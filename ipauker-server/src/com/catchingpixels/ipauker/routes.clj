(ns com.catchingpixels.ipauker.routes
  (:use compojure.core
	clojure.contrib.logging
	clojure.contrib.def
	hiccup.core
	[hiccup.middleware :only (wrap-base-url)]
	[ring.middleware.multipart-params :only (wrap-multipart-params)]
	com.catchingpixels.ipauker.database
	com.catchingpixels.ipauker.xml
	com.catchingpixels.ipauker.processing)
  (:require [compojure.route :as route]
	    [compojure.handler :as handler]
	    [ring.util.response :as response]
	    [clojure.contrib.lazy-xml :as lxml]))

(defvar- dummy-user 0)

(defn- wrap-api [handler]
  (fn [req]
    (let [uri (:uri req)]
      (info (str "API request " uri " with params " (:params req)))
      (try
	(handler req)
	(catch Exception exc
	  (warn "Exception caught in API request" exc)
	  {:status 400})))))

(defn- pauker-upload [lesson-id lesson-name xml-file]
  (try
    (transaction
     (let [lesson (get-or-create-lesson-generic dummy-user lesson-id lesson-name)]
       (process-pauker-upload lesson xml-file))
     (html [:h1 "Upload successful"]))
    (catch Exception exc
      (warn "Exception caught in upload" exc)
      (html [:h1 "Upload failed"]
	    [:p (str exc)]))))

(defn- cards-update [lesson-name xml-file]
  (transaction
   (let [lesson (get-lesson dummy-user lesson-name true)]
     (process-cards-update lesson xml-file))
   "OK"))

(defn- list-diff [lesson-name since-version]
  (transaction
   (let [lesson (get-lesson dummy-user lesson-name true)]
     (with-out-str (lxml/emit (xml-list lesson since-version))))))

(defn- index-page []
  (let [lessons (lesson-list dummy-user)]
    (html [:h1 "iPauker Lessons"]
	  [:table
	   (map (fn [lesson]
		  [:tr
		   [:td [:a {:href (str "/ipauker/lesson/" (:id lesson))} (escape-html (:name lesson))]]
		   [:td (str (:version lesson))]
		   [:td [:a {:href (str "/ipauker/upload/" (:id lesson))} "Upload"]]])
		lessons)]
	  [:p [:a {:href "/ipauker/upload"} "Upload new"]])))

(defn- upload-page [lesson-id]
  (html [:h1 "Upload"]
	[:form {:action "/ipauker/upload" :method "post" :enctype "multipart/form-data"}
	 (if lesson-id
	   [:input {:type "hidden" :name "lesson-id" :value (str lesson-id)}]
	   [:p "Lesson name"
	    [:input {:type "text" :name "lesson-name"}]])
	 [:p "Pauker file"
	  [:input {:type "file" :name "xml"}]]
	 [:input {:type "submit" :value "Submit"}]]))

(defn- lesson-page [lesson-id]
  (transaction
   (let [lesson (get-lesson-by-id dummy-user lesson-id)
	 cards (lesson-cards lesson false 0)]
     (html [:h1 "Lesson " (escape-html (:name lesson))]
	   [:table
	    (map (fn [card]
		   [:tr
		    [:td (escape-html (:text (:front card)))]
		    [:td (escape-html (:text (:reverse card)))]])
		 cards)]))))

(defroutes main-routes
  (GET "/" []
       (response/redirect "/ipauker"))
  (GET "/ipauker" []
       (index-page))
  (GET "/ipauker/upload" []
       (upload-page nil))
  (GET "/ipauker/upload/:id" [id]
       (upload-page (java.lang.Long. id)))
  (GET "/ipauker/lesson/:id" [id]
       (lesson-page (java.lang.Long. id)))
  (wrap-multipart-params
   (POST "/ipauker/upload" {{lesson-id :lesson-id
			     lesson-name :lesson-name
			     xml :xml} :params}
	 (pauker-upload (and lesson-id (java.lang.Long. lesson-id))
			lesson-name
			(:tempfile xml))))
  (wrap-api
   (wrap-multipart-params
    (POST "/ipauker/update" {{lesson-name :lesson
			      xml :data} :params}
	  (cards-update lesson-name
			(org.apache.commons.io.IOUtils/toInputStream xml)))))
  (wrap-api
   (POST "/ipauker/list" {{lesson-name :lesson
			   since-version :version} :params}
	 (list-diff lesson-name (java.lang.Integer. since-version))))
  (route/not-found (html [:h1 "Page not found"])))

(def app
     (-> (handler/site main-routes)
	 (wrap-base-url)))

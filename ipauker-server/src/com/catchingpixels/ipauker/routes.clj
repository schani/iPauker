(ns com.catchingpixels.ipauker.routes
  (:use compojure.core
	clojure.contrib.logging
	clojure.contrib.def
	hiccup.core
	[hiccup.middleware :only (wrap-base-url)]
	[ring.middleware.multipart-params :only (wrap-multipart-params)]
	com.catchingpixels.ipauker.database
	com.catchingpixels.ipauker.processing)
  (:require [compojure.route :as route]
	    [compojure.handler :as handler]))

(defvar- dummy-user 0)

(defn- wrap-api [handler]
  (fn [req]
    (let [uri (:uri req)]
      (try
	(handler req)
	(catch Exception exc
	  (warn "Exception caught in API request" exc)
	  {:status 400})))))

(defn- pauker-upload [lesson-id lesson-name xml-file]
  (info (str "Upload XML file " xml-file))
  (try
    (transaction
     (let [lesson (get-or-create-lesson-generic dummy-user lesson-id lesson-name)]
       (process-pauker-upload lesson xml-file))
     (html [:h1 "Upload successful"]))
    (catch Exception exc
      (warn "Exception caught in upload" exc)
      (html [:h1 "Upload failed"]
	    [:p (str exc)]))))

(defn- index-page []
  (let [lessons (lesson-list dummy-user)]
    (html [:h1 "iPauker Lessons"]
	  [:table
	   (map (fn [lesson]
		  [:tr
		   [:td [:a {:href (str "/lesson/" (:id lesson))} (escape-html (:name lesson))]]
		   [:td (str (:version lesson))]
		   [:td [:a {:href (str "/upload/" (:id lesson))} "Upload"]]])
		lessons)]
	  [:p [:a {:href "/upload"} "Upload new"]])))

(defn- upload-page [lesson-id]
  (html [:h1 "Upload"]
	[:form {:action "/upload" :method "post" :enctype "multipart/form-data"}
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
       (index-page))
  (GET "/upload" []
       (upload-page nil))
  (GET "/upload/:id" [id]
       (upload-page (java.lang.Long. id)))
  (GET "/lesson/:id" [id]
       (lesson-page (java.lang.Long. id)))
  (wrap-multipart-params
   (POST "/upload" {{lesson-id :lesson-id
		     lesson-name :lesson-name
		     xml :xml} :params}
	 (pauker-upload (and lesson-id (java.lang.Long. lesson-id))
			lesson-name
			(:tempfile xml))))
  (route/not-found "<h1>Page not found</h1>"))

(def app
     (-> (handler/site main-routes)
	 (wrap-base-url)))

(ns com.catchingpixels.ipauker.database
  (:require [clojureql.core :as ql]
	    [clojure.contrib.sql :as sql]))

(def jdbc-settings
   {:classname "org.h2.Driver"
    :subprotocol "h2:file"
    :subname "/tmp/demo"
    :user "sa"
    :password ""})

(defn- table-exists [table-name]
  (let [tables (resultset-seq
		(-> (sql/connection)
		    (.getMetaData)
		    (.getTables nil nil "%" (into-array ["TABLE"]))))]
    (some #(= (:table_name %) (.toUpperCase (name table-name))) tables)))

(defmacro transaction [& body]
  `(let [body-func# (fn [] ~@body)]
     (if (sql/find-connection)
       (sql/transaction
	(body-func#))
       (sql/with-connection jdbc-settings
	 (sql/transaction
	  (body-func#))))))

(transaction
  (if-not (table-exists :lesson)
    (sql/create-table :lesson
		      [:id "identity"]
		      [:name "varchar"]
		      [:owner "bigint"]
		      [:version "integer"]))
  (if-not (table-exists :card)
    (sql/create-table :card
		      [:id "identity"]
		      [:lesson "bigint"]
		      [:version "integer"]
		      [:deleted "boolean"]
		      [:front_text "varchar"]
		      [:front_batch "integer"]
		      [:front_timestamp "bigint"]
		      [:reverse_text "varchar"]
		      [:reverse_batch "integer"]
		      [:reverse_timestamp "bigint"])))

(defn- create-lesson [owner name]
  (transaction
   (ql/conj! (ql/table :lesson)
	     {:name name
	      :owner owner
	      :version 0})))

(defn delete-lesson [lesson]
  (transaction
   (ql/disj! (ql/table :card)
	     (ql/where (= :lesson (:id lesson))))
   (ql/disj! (ql/table :lesson)
	     (ql/where (= :id (:id lesson))))
   nil))

(defn- lesson-from-result-set [rs fail-if-not-found]
  (when (> (count rs) 1)
    (throw (Exception. "Database inconsistent")))
  (when (and fail-if-not-found (zero? (count rs)))
    (throw (Exception. "Lesson not found")))
  (first rs))

(defn get-lesson [owner lesson-name fail-if-not-found]
  (transaction
   (ql/with-results [rs (ql/select (ql/table :lesson)
				       (ql/where (and (= :owner owner)
						      (= :name lesson-name))))]
     (lesson-from-result-set rs fail-if-not-found))))

(defn get-lesson-by-id [owner id]
  (transaction
   (ql/with-results [rs (ql/select (ql/table :lesson)
				   (ql/where (and (= :owner owner)
						  (= :id id))))]
     (lesson-from-result-set rs true))))

(defn get-or-create-lesson [owner name]
  (transaction
   (let [lesson (get-lesson owner name false)]
     (if lesson
       lesson
       (do
	 (create-lesson owner name)
	 (get-lesson owner name true))))))

(defn get-or-create-lesson-generic [owner id name]
  (if id
    (get-lesson-by-id owner id)
    (get-or-create-lesson owner name)))

(defn update-lesson [lesson]
  (transaction
   (ql/update-in! (ql/table :lesson)
		  (ql/where (= :id (:id lesson)))
		  lesson)
   nil))

(defn lesson-list [owner]
  (transaction
   (ql/with-results [rs (ql/select (ql/table :lesson)
				   (ql/where (= :owner owner)))]
     (doall rs))))

(defn- sidify-card [card]
  (assoc (dissoc card
		 :front_text :front_batch :front_timestamp
		 :reverse_text :reverse_batch :reverse_timestamp)
    :front {:text (:front_text card)
	    :batch (:front_batch card)
	    :timestamp (:front_timestamp card)}
    :reverse {:text (:reverse_text card)
	      :batch (:reverse_batch card)
	      :timestamp (:reverse_timestamp card)}))

(defn lesson-cards [lesson include-deleted since-version]
  (transaction
   (let [lesson-id (:id lesson)]
     (ql/with-results [rs (if include-deleted
			    (ql/select (ql/table :card)
				       (ql/where (and (= :lesson lesson-id)
						      (> :version since-version))))
			    (ql/select (ql/table :card)
				       (ql/where (and (= :lesson lesson-id)
						      (> :version since-version)
						      (= :deleted false)))))]
       (doall (map sidify-card rs))))))

(defn- dbify-card [card]
  (let [front (:front card)
	reverse (:reverse card)]
    (assoc (dissoc card :front :reverse)
      :front_text (:text front)
      :front_batch (:batch front)
      :front_timestamp (:timestamp front)
      :reverse_text (:text reverse)
      :reverse_batch (:batch reverse)
      :reverse_timestamp (:timestamp reverse))))

(defn update-cards [cards]
  (transaction
   (doseq [card (map dbify-card cards)]
     (if (:id card)
       (ql/update-in! (ql/table :card)
		      (ql/where (= :id (:id card)))
		      card)
       (ql/conj! (ql/table :card)
		 card)))
   nil))

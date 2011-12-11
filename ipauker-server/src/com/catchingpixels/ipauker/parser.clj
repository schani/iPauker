(ns com.catchingpixels.ipauker.parser
  (:require [clojure.xml :as xml]
	    [clojure.contrib.seq :as seq]))

(defn- subtag [xml tag]
  (seq/find-first #(= (:tag %) tag) (:content xml)))

(defn- xml-int [s default]
  (if s
    (java.lang.Integer. s)
    default))

(defn- xml-int-opt [s]
  (if (= s "None")
    nil
    (xml-int s nil)))

(defn- parse-pauker-side [side batch]
  {:text (first (:content (subtag side :Text)))
   :timestamp (xml-int (:LearnedTimestamp (:attrs side)) nil)
   :batch (or batch
	      (xml-int (:Batch (:attrs side)) -2))})

(defn parse-pauker [lesson input]
  (let [xml (xml/parse input)
	batches (filter #(= (:tag %) :Batch) (:content xml))]
    (apply concat (map-indexed (fn [i batch]
				 (let [front-batch (- i 2)
				       cards (:content batch)]
				   (map (fn [card]
					  {:lesson (:id lesson)
					   :version (:version lesson)
					   :deleted false
					   :front (parse-pauker-side (subtag card :FrontSide) front-batch)
					   :reverse (parse-pauker-side (subtag card :ReverseSide) nil)})
					cards)))
			       batches))))

(defn- parse-card-side [side]
  {:batch (xml-int (:batch (:attrs side)) nil)
   :timestamp (xml-int-opt (:timestamp (:attrs side)))
   :text (first (:content side))})

(defn parse-cards [lesson input]
  (let [xml (xml/parse input)]
    (map (fn [card]
	   {:lesson (:id lesson)
	    :version (:version lesson)
	    :deleted false
	    :front (parse-card-side (subtag card :front))
	    :reverse (parse-card-side (subtag card :reverse))})
	 (:content xml))))

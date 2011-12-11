(ns com.catchingpixels.ipauker.processing
  (:use com.catchingpixels.ipauker.database
	com.catchingpixels.ipauker.parser
	com.catchingpixels.ipauker.diff))

(defn- process [lesson input parser is-full-list]
  (transaction
   (let [lesson (assoc lesson :version (inc (:version lesson)))
	 new-cards (parser lesson input)
	 current-cards (lesson-cards lesson true -1)
	 diff-cards (cards-diff (:version lesson) current-cards new-cards is-full-list)]
     (update-lesson lesson)
     (update-cards diff-cards))))

(defn process-pauker-upload [lesson input]
  (process lesson input
	   parse-pauker true))

(defn process-cards-update [lesson input]
  (process lesson input
	   parse-cards false))

(ns com.catchingpixels.ipauker.processing
  (:use com.catchingpixels.ipauker.database
	com.catchingpixels.ipauker.parser
	com.catchingpixels.ipauker.diff))

(defn process-pauker-upload [owner lesson-name input]
  (transaction
   (let [lesson (get-or-create-lesson owner lesson-name)
	 lesson (assoc lesson :version (inc (:version lesson)))
	 new-cards (parse-pauker lesson input)
	 current-cards (lesson-cards lesson true -1)
	 diff-cards (cards-diff (:version lesson) current-cards new-cards true)]
     (update-lesson lesson)
     (update-cards diff-cards))))

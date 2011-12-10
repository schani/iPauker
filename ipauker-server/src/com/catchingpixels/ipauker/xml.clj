(ns com.catchingpixels.ipauker.xml
  (use com.catchingpixels.ipauker.database))

(defn xml-lesson-list [owner]
  (let [ll (lesson-list owner)]
    {:tag :lessons
     :attrs {:format "0.1"}
     :content (map (fn [l]
		     {:tag :lesson
		      :attrs {:version (str (:version l))}
		      :content [(:name l)]})
		   ll)}))

(defn- xml-pauker-side [side tag include-batch]
  (let [attrs {:Orientation "LTR"
	       :RepeatByTyping "false"}
	attrs (if (and include-batch
		       (> (:batch side) 0))
		(assoc attrs :Batch (str (:batch side)))
		attrs)
	attrs (if (and (> (:batch side) 0)
		       (:timestamp side))
		(assoc attrs :LearnedTimestamp (str (:timestamp side)))
		attrs)]
    {:tag tag
     :attrs attrs
     :content [{:tag :Text
		:content [(:text side)]}]}))

(defn xml-pauker-dump [lesson]
  (let [all-cards (lesson-cards lesson false -1)
	batches (group-by #(:batch (:front %)) all-cards)
	max-batch (apply max -3 (keys batches))]
    ;(print batches "\n")
    {:tag :Lesson
     :attrs {:LessonFormat "1.7"}
     :content (concat [{:tag :Description
			:content [(str (:name lesson) " version " (:version lesson) " by test@example.com")]}]
		      (map (fn [batch]
			     (let [cards (batches batch)]
			       ;(print "batch " batch "\n")
			       ;(print "cards " cards "\n")
			       {:tag :Batch
				:content (map (fn [card]
						{:tag :Card
						 :content [(xml-pauker-side (:front card) :FrontSide false)
							   (xml-pauker-side (:reverse card) :ReverseSide true)]})
					      cards)}))
			   (range -2 (inc max-batch))))}))

(defn- xml-side [tag card]
  (let [side (card tag)
	xml {:tag tag
	     :content [(:text side)]}]
    (if (:deleted card)
      xml
      (assoc xml
	:attrs {:batch (str (:batch side))
		:timestamp (str (or (:timestamp side) "None"))}))))

(defn xml-list [lesson since-version]
  (let [cards (lesson-cards lesson true since-version)]
    {:tag :cards
     :attrs {:format "0.1"
	     :version (str (:version lesson))}
     :content (map (fn [card]
		     (let [xml {:tag :card
				:content [(xml-side :front card)
					  (xml-side :reverse card)]}]
		       (if (:deleted card)
			 (assoc xml :attrs {:deleted "True"})
			 xml)))
		   cards)}))

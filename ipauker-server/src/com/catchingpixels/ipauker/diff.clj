(ns com.catchingpixels.ipauker.diff)

(defn- cards-map [cards]
  (into (hash-map) (map (fn [c] [[(:text (:front c)) (:text (:reverse c))] c]) cards)))

(defn- cards-equal? [a b]
  (and (= (:front a) (:front b))
       (= (:reverse a) (:reverse b))))

(defn- updated-side [old new]
  (let [new-timestamp (:timestamp new)]
    (if (or (nil? new-timestamp)
	    (nil? (:timestamp old))
	    (> new-timestamp (:timestamp old)))
      (assoc old
	:batch (:batch new)
	:timestamp (or new-timestamp (:timestamp old)))
      old)))

(defn- updated-card [old new version]
  (assoc old
    :version version
    :deleted (:deleted new)
    :front (updated-side (:front old) (:front new))
    :reverse (updated-side (:reverse old) (:reverse new))))

(defn cards-diff [version old-cards new-cards is-full-list]
  (let [old-cards-map (cards-map old-cards)
	new-cards-map (cards-map new-cards)
	old-new-diff (keep (fn [entry]
			     (let [[text card] entry
				   old-card (old-cards-map text)]
			       (if old-card
				 (cond (not (cards-equal? card old-card)) (updated-card old-card card version)
				       (:deleted old-card) (assoc old-card :deleted false :version version))
				 card)))
			   new-cards-map)
	old-deleted (if is-full-list
		      (let [diff-map (cards-map old-new-diff)]
			(keep (fn [entry]
				(let [[text card] entry]
				  (if (and (not (:deleted card))
					   (not (new-cards-map text)))
				    (assoc card :deleted true :version version))))
			      old-cards-map))
		      [])]
    (concat old-new-diff old-deleted)))

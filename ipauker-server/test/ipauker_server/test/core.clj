(ns ipauker-server.test.core
  (:use com.catchingpixels.ipauker.parser
	com.catchingpixels.ipauker.xml
	com.catchingpixels.ipauker.database
	com.catchingpixels.ipauker.processing
	clojure.test)
  (:require [clojure.xml :as xml]
	    [clojure.contrib.lazy-xml :as lxml]))

(def test-dir (java.io.File. (str (System/getProperty "user.dir") "/../appengine/tests")))

(def test-user -1)
(def test-lesson-name "bla")

(defn expected [name]
  (xml/parse (java.io.File. test-dir (str "expected." name))))

(defn xml-rt [xml]
  (xml/parse (org.apache.commons.io.IOUtils/toInputStream (with-out-str (lxml/emit xml)))))

(defn do-lessons-test [version]
  (is (= (xml-rt (xml-lesson-list test-user))
	 (expected (str "lessons" version)))))

(defn do-dump-test [version]
  (transaction
   (let [lesson (get-lesson test-user test-lesson-name false)]
     (when lesson
       (is (= (xml-rt (xml-pauker-dump lesson))
	      (expected (str "dump" version))))))))

(defn do-list-tests [version]
  (transaction
   (let [lesson (get-lesson test-user test-lesson-name false)]
     (when lesson
       (doseq [since-version (range 0 (inc (:version lesson)))]
	 (is (= (xml-rt (xml-list lesson since-version))
		(expected (str "list" since-version "to" (:version lesson))))))))))

(defn do-version-tests [version]
  (do-lessons-test version)
  (do-dump-test version)
  (do-list-tests version))

(deftest processing
  (transaction
   (let [lesson (get-lesson test-user test-lesson-name false)]
     (when lesson
       (delete-lesson lesson))))
  (do-version-tests 0)
  (loop [v 1]
    (let [upload-file (java.io.File. test-dir (str "upload." v ".xml"))
	  update-file (java.io.File. test-dir (str "update." v ".xml"))]
      (cond
       (.exists upload-file)
       (do
	 (print "upload " v "\n")
	 (process-pauker-upload test-user test-lesson-name upload-file)
	 (do-version-tests v)
	 (recur (inc v)))
       (.exists update-file)
       (do
	 (print "update " v "\n")
	 (process-cards-update test-user test-lesson-name update-file)
	 (do-version-tests v)
	 (recur (inc v)))))))

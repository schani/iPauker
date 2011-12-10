(defproject ipauker-server "0.0.1-SNAPSHOT"
  :description "iPauker Server"
  :dependencies [[org.clojure/clojure "1.2.1"]
		 ;[compojure "1.0.0-SNAPSHOT"]
		 ;[hiccup "0.3.7"]
		 [commons-io "1.4"]
		 [com.h2database/h2 "1.3.162"]
		 [clojureql "1.1.0-SNAPSHOT"]]
  :dev-dependencies [[swank-clojure "1.4.0-SNAPSHOT"]
		     [lein-ring "0.4.6"]
		     [ring-serve "0.1.1"]]
  :ring {:handler com.catchingpixels.ipauker.routes/app})

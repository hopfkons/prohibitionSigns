;;;
;;; rtouchequirememts:
;;; the library "xmls" needs to be present, install with quicklisp:
;;; assuming, quicklisp (http://www.quicklisp.org/beta/) is installed, just evaluate (ql:quickload "xmls") once to install xmls
;;;

;; Welche Arten von Polygonen soll es außer den durch die OSM-Objekte definierten geben?
;;  -> 'grow-region' um ein Polygon herum, bis maximal zur Position des Schildes, kein anderes Objekt treffend
;;     Bsp.: Nicht-Rauchen-Schild vor dem (nicht verzeichneten) Betriebsgelände einer Gasanlage
;;  -> 'inner-region' als maximal großes Polygon, ohne an andere Objekte heranzustoßen
;;     Bsp.: Auffahrt, die nicht blockiert werden darf...



(eval-when (:compile-toplevel :load-toplevel :execute)
  (require 'xmls)
  (setf *read-default-float-format* 'double-float ; geo-coorinates require double-float precision, so make sure Lisp parsing defaults to that
	*print-right-margin* 140)) ; for pretty-printing in the age of wide screens...

(defparameter *main-dir* (or (probe-file "/Users/diedrich/Documents/Artikel/infoCup")
			     (probe-file "/ADD/YOUR/PATH/TO/THIS/OR-LIST/AS/SHOWN/ABOVE"))
  "local pathname to the git repository")

(defparameter *swi-path* (or (probe-file "/usr/local/bin/swipl")
			     (probe-file "/ADD/YOUR/PATH/TO/SWI_PROLOG/"))
  "path to SWI prolog executable")

;; Alle GPS-Fixes aus den JPGs ziehen:
;; for img in *.JPG ; do exiftool -n -exif:gpslatitude -exif:gpslongitude "$img" >> fixes.dat ; done
;; grep "Longitude" fixes.dat | awk '{print $4}' > lons.dat
;; grep "Latitude" fixes.dat | awk '{print $4}' > lats.dat

(defparameter *evaluation* '(("testdaten_husum" "husum.osm" #c(54.4730515 9.0448611) (no_mobile)   (kml "groundtruth_01.kml") "img_01.jpg" "nicht verzeichnetes Betriebsgelaende der Erdgasversorgung")
			     ("testdaten_husum" "husum.osm" #c(54.4733881 9.0440236) (no_fishing)  (kml "groundtruth_02.kml") "img_02.jpg" "Teil des Hafenbeckens im Außenhafen")
			     ("testdaten_husum" "husum.osm" #c(54.4716144 9.0479291) (no_mobile no_fire no_smoking)  (id 309906400) "img_03.jpg" "Betriebsgelände Erdgasversorgung")
                             ("testdaten_husum" "husum.osm" #c(54.475837 9.050232) (no_bike_leaning)  (kml "groundtruth_04.kml") "img_04.jpg" "nicht eingezeichnetes Brueckengelaender")
                             ("testdaten_husum" "husum.osm" #c(54.48113 9.0524352) (dogs_on_leash)  (id 16796252) "img_05.jpg" "Schlosspark")
                             ("testdaten_husum" "husum.osm" #c(54.4804753 9.050682) (no_stepping_on_ice)  (id 17455278) "img_06.jpg" "Wassergraben im Schlosspark")
                             ("testdaten_husum" "husum.osm" #c(54.4735129 9.0259097) (dogs_on_leash no_riding)  (id 179161174) "img_07.jpg" "Deich entlang der Strasse, nicht intuitiv eingezeichnet")
                             ("testdaten_husum" "nordstrand.osm" #c(54.5281295 8.8716039) (no_swimming)  (kml "groundtruth_08.kml") "img_08.jpg" "Hafen Schuettsiel nicht eingezeichnet")
                             ("testdaten_husum" "egenbuettel.osm" #c(53.6469926 9.8753789) (dogs_on_leash) (kml "egenbuettel.kml") "img_egenbuettel.jpg" "nicht verzeichnetes Gebiet um Regenrueckhaltebecken")
                             ("testdaten_husum" "egenbuettel.osm" #c(53.6469926 9.8753789) (no_stepping_on_ice) (id 115762228) "img_egenbuettel.jpg" "nicht verzeichnetes Gebiet um Regenrueckhaltebecken")
                             
                             ("testdaten_bamberg2" "erba.osm" #c(49.8944118 10.8798256) (no_smoking) (id 36961814) "DSC00222.JPG" "Wohnhaus")
                             ("testdaten_bamberg2" "erba.osm" #c(49.9008656 10.8698721) (no_smoking no_dogs) (id 34550988) "DSC00223.JPG" "Bäckerei Seel")
                             ("testdaten_bamberg2" "erba.osm" #c(49.9016917 10.8694019) (no_access) (id 45443013) "DSC00224.JPG" "Wehr")
                             ("testdaten_bamberg2" "erba.osm" #c(49.9024140 10.8704406) (dogs_on_leash no_camping no_fire) (id 161568873) "DSC00226.JPG" "ERBA-Park")
                             ("testdaten_bamberg2" "erba.osm" #c(49.9020840 10.8699797) (dogs_on_leash) (id 161568873) "DSC00225.JPG" "ERBA-Park")
                             ("testdaten_bamberg" "erba.osm" #c(49.8963167 10.88035) (no_dogs) (kml "SURF021.truth.kml") "SURF021.JPG" "Rosengarten")
                             ("testdaten_bamberg" "erba.osm" #c(49.8963167 10.88035) (no_dogs) (id 134995803) "SURF022.jpg" "Spielplatz")
                             ("testdaten_bamberg" "erba.osm" #c(49.89836694 10.878705) (no_dogs) (id 36963529) "SURF023.jpg" "Spielplatz")
                             ("testdaten_bamberg" "erba.osm" #c(49.9000 10.87365) (no_dogs) (id 43913713) "SURF024.jpg" "Bolzplatz")
                             ("testdaten_bamberg" "erba.osm" #c(49.900733 10.87233) (dogs_on_leash no_fire no_camping) (id 161568873) "SURF025.jpg" "Erbapark")
                             ("testdaten_bamberg" "erba.osm" #c(49.903025 10.87109) (dogs_on_leash no_fire no_camping) (id 161568873) "SURF026.jpg" "Erbapark, anderer Eingang")
                            
                             ("testdaten_bamberg" "hof_see.osm" #c(50.285120 11.911331) (no_swimming) (kml "SURF012.truth.kml") "SURF012.jpg" "See in Hof")
                             ("testdaten_bamberg" "treppendorf.osm" #c(49.80356 10.73249) (no_fire) (id 105017792) "SURF011.jpg" "Betriebsgelaende Fa. Thomann")
                             

                             ("testdaten_bamberg" "volkspark.osm" #c(49.901581 10.926233) (no_camping) (id 310015311) "SURF013.jpg" "Camping am Volkspark 1")
                             ("testdaten_bamberg" "volkspark.osm" #c(49.901637 10.927609) (no_camping) (kml "SURF014.truth.kml") "SURF014.jpg" "Camping am Volkspark 2")
                             ("testdaten_bamberg" "volkspark.osm" #c(49.900451 10.927930) (no_dogs no_smoking) (id 261563377) "SURF015.jpg" "Haupttribühne im Fuchsstadion")

                             ("testdaten_bamberg" "insel.osm" #c(49.892926 10.887502) (no_smoking) (kml "SURF010.truth.kml") "SURF010.jpg" "Café Müller")                             
                             ("testdaten_bamberg" "insel.osm" #c(49.9015242 10.8846881) (no_access) (kml "SURF006.truth.kml") "SURF006.jpg" "Betriebsgelände der Stadtwerke Bamberg")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8949422 10.8890100) (no_smoking no_dogs no_skate) (kml "DSC00208.truth.kml") "DSC00208.JPG" "City-Markt")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8928841 10.8881799) (no_dogs) (id 37143318) "DSC00210.JPG" "Der Beck am grünen Markt")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8928436 10.8892536) (no_dogs) (id 37698726) "DSC00211.JPG" "Lido Eis-Café, Kesslerstrasse 14")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8934012 10.8904336) (no_dogs) (id 37698744) "DSC00212.JPG" "Dönerbude")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8920529 10.8912931) (no_dogs) (id 37142771) "DSC00213.JPG" "Bäckerrei Postler")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8922222 10.8906636) (no_dogs) (id 37380249) "DSC00214.JPG" "Teehaus Scharnke")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8922935 10.8899320) (no_dogs no_smoking no_skate no_food) (id 37380243) "DSC00215.JPG" "Bonscheladen")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8923294 10.8893056) (no_dogs no_smoking no_skate) (id 37380273) "DSC00216.JPG" "City-Markt Lange Straße")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8934680 10.8860983) (no_dogs) (id 37752043) "DSC00217.JPG" "Kapuzinerbeck")                             
                             ("testdaten_bamberg2" "insel.osm" #c(49.8933569 10.8861801) (no_dogs) (id 37752045) "DSC00218.JPG" "?")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8916340 10.8847822) (no_dogs no_smoking) (id 37894985) "DSC00219.JPG" "Bäckerei Seel")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8917252 10.8844008) (no_dogs no_smoking no_food) (id 37894985) "DSC00220.JPG" "Klamottengeschäft")
                             ("testdaten_bamberg2" "insel.osm" #c(49.8917409 10.8843048) (no_dogs) (id 37901921) "DSC00221.JPG" "Café Zuckerstück")
                             ("testdaten_bamberg"  "insel.osm" #c(49.8938833 10.891567) (no_food) (id 37379401) "SURF016.JPG" "Geschäft")
                             ("testdaten_bamberg"  "insel.osm" #c(49.8935000 10.890967) (no_dogs) (id 37752274) "SURF017.JPG" "Bäckerei")
                             ("testdaten_bamberg"  "insel.osm" #c(49.8940167 10.8896167) (no_dogs no_food) (id 37380633) "SURF018.JPG" "Geschäft")

                             ("testdaten_bamberg" "insel.osm" #c(49.89425 10.8898833) (no_food) (id 37380889) "SURF019.JPG" "Geschäft")
                             ("testdaten_bamberg" "insel.osm" #c(49.89435 10.8899833) (no_food) (id 37380889) "SURF020.JPG" "Geschäft wie SURF019, 2. Eingang")
                             ("testdaten_bamberg" "insel.osm" #c(49.891751 10.881916) (dogs_on_leash) (id 128848081) "SURF021.JPG" "Rosengarten")

                             ;Fehler: See 50m zu weit weg ("testdaten_hamburg" "krupunder.osm" #c(53.6222675 9.8753814) (no_swimming) (id 10714528) "NO_FOTO_YET" "Nicht-Schwimmen-Schild fernab vom See")


                             ("testdaten_nuernberg" "nuernberg.osm" #c(49.4516844444444 11.0873994444444) (no_dogs no_camping) (kml "IMG_9351.kml") "IMG_9351.JPG" "Biotop")

                             ;funktioniert nicht: Eingang 50m zu weit weg 
                             ("testdaten_nuernberg" "nuernberg.osm" #c(49.452018 11.086717) (no_smoking no_alc no_skate) (kml "IMG_9352.kml") "IMG_9352.JPG" "U-Bahn Woehrder Wiese")

                             ; Pop-Up-Poly wird *in* ein nahestehendes Gebaeude gezeichnet 
                             ("testdaten_nuernberg" "nuernberg.osm" #c(49.452104 11.084936) (no_littering) (kml "IMG_9353.kml") "IMG_9353.JPG" "Chinecitta, Muellplatz")
                             
                             ("testdaten_nuernberg" "nuernberg.osm" #c(49.450805 11.078335) (no_smoking no_food) (id 144721691) "IMG_9362.JPG" "Lorenzkirche")
                             ("testdaten_nuernberg" "nuernberg.osm" #c(49.452034 11.082960) (no_dogs) (id 319143577) "IMG_9354.JPG" "Museumsplatz")
                             ("testdaten_nuernberg" "rennweg.osm" #c(49.460721 11.092676) (no_smoking no_alc no_skate) (kml "IMG_9383.kml") "IMG_9383.JPG" "U Rennweg")
                             ("testdaten_nuernberg" "rennweg.osm" #c(49.463272 11.077557) (no_smoking no_alc no_skate) (kml "IMG_9385.kml") "IMG_9385.JPG" "U Kaulbachplatz")
                             ("testdaten_nuernberg" "rennweg.osm" #c(49.461880 11.077198) (no_access) (kml "IMG_9386.kml") "IMG_9386.JPG" "U Kaulbachplatz")
                             ("testdaten_nuernberg" "kaulbachstrasse.osm" #c(49.461190 11.077353) (no_smoking no_dogs no_skate) (id 148698877) "IMG_9388.JPG" "Geschaeft")

                             ("testdaten_nuernberg" "kaulbachstrasse.osm" #c(49.459475 11.069891) (no_littering) (kml "IMG_9389.kml") "IMG_9389.JPG" "Müllcontainer")
                             ("testdaten_nuernberg" "kaulbachstrasse.osm" #c(49.458978 11.069725) (no_dogs) (kml "IMG_9391.kml") "IMG_9391.JPG" "Grünstreifen")
                             ("testdaten_nuernberg" "kaulbachstrasse.osm" #c(49.45780 11.067970) (no_dogs) (id 240053214) "IMG_9394.JPG" "Bäckerei")
                             ("testdaten_nuernberg" "kaulbachstrasse.osm" #c(49.458287 11.066067) (no_littering) (kml "IMG_9396.kml") "IMG_9396.JPG" "Abfallplatz")


                             ("testdaten_nuernberg" "erlangen.osm" #c(49.600911 11.005776) (no_dogs) (id 34949279) "IMG_9410.JPG" "Spielplatz")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.600573 11.005284) (dogs_on_leash) (id 28388564) "IMG_9412.JPG" "Park")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.600544 11.005092) (no_bike_leaning) (id 225298804) "IMG_9413.JPG" "Fassade")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.599686 11.004977) (no_bike_leaning) (kml "IMG_9414.kml") "IMG_9414.JPG" "Fassade")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.599135 11.003706) (no_dogs) (id 205107563) "IMG_9416.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.599167 11.003616) (no_dogs) (kml "IMG_9417.kml") "IMG_9417.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.599167 11.003616) (no_dogs) (id 192727982) "IMG_9418.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.598428 11.003586) (no_dogs) (id 192727968) "IMG_9420.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.597804 11.003304) (no_dogs no_smoking) (id 205111468) "IMG_9423.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.597656 11.003351) (no_dogs) (id 206092372) "IMG_9421.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.596952 11.003480) (no_bike_leaning) (kml "IMG_9424.kml") "IMG_9424.JPG" "Fassade")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.596566 11.004027) (no_smoking) (id 206435578) "IMG_9425.JPG" "Geschäft")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.596641 11.004755) (no_bike_leaning) (id 44315732) "IMG_9427.JPG" "WC")
                             ("testdaten_nuernberg" "erlangen.osm" #c(49.596024 11.002379) (no_smoking) (id 31509300) "IMG_9428.JPG" "Bahnhof Erlangen")

                             ("testdaten_nuernberg" "nuernberg2.osm" #c(49.450640 11.070410) (no_dogs) (kml "IMG_9373.kml") "IMG_9373.JPG" "Baecker")
                             ("testdaten_nuernberg" "nuernberg2.osm" #c(49.449687 11.069101) (no_alc no_smoking no_skate) (kml "IMG_9371.kml") "IMG_9371.JPG" "U-Bahn")
                             ; same kml file for IMG_9371 and IMG_9376
                             ("testdaten_nuernberg" "nuernberg2.osm" #c(49.450356 11.070748) (no_alc no_smoking no_skate) (kml "IMG_9371.kml") "IMG_9376.JPG" "U-Bahn")
                             ;("testdaten_nuernberg" "nuernberg2.osm" #c(49.450273 11.071845) (no_dog) (kml "IMG_9369.kml") "IMG_9369.JPG" "Bar")
)
  "test data and ground truth")


#|
Fälle, in denen nearest-object besser ist:
((0.0 0.0 ID 0 1 "Lido Eis-Café, Kesslerstrasse 14") 
(0 0 ID 0 1 "Dönerbude") 
(0 0 ID 0 1 "?") 

(0.0 0.00586359 KML 0.0133505 0.138164 "U-Bahn Woehrder Wiese") 
(0.0 1.84275E-5 KML 1.84275E-5 0.0980868 "Chinecitta, Muellplatz") 
(0 0.068144 KML 0.068144 0.825909 "U Kaulbachplatz") 

(0 0 KML 0.0 0.0237606 "Müllcontainer") 
(0 0 KML 0.0394638 0.0394638 "Grünstreifen") 
(0 0 KML 0 0.0786081 "Fassade")  --> NN wählt Straße aus
(0.0 0.0 KML 0.0 0.170576 "Fassade")) --> großer Abstand zwischen Schildpos. und ground truth; NN wählt die Straße als Gültigkeitsbereich aus 
|#


(defparameter *prohibition-labels* '((NO_FISHING . "no-fishing") 
                                     (NO_BIKE_LEANING . "don't-lean-bikes-against") 
                                     (NO_STEPPING_ON_ICE . "stay-off-the-ice") 
                                     (NO_RIDING . "no-horse-riding") 
                                     (NO_DRIVING . "no-vehicles") 
                                     (NO_SWIMMING . "no-swimming")
                                     ;(NO_ENTERING . "do-not-enter") 
                                     (NO_MOBILE . "no-mobile-phones") 
                                     (NO_FIRE . "no-open-fire") 
                                     (NO_FOOD . "no-food") 
                                     (NO_CAMPING . "no-camping") 
                                     (NO_SKATE . "no-skating") 
                                     (DOGS_ON_LEASH . "keep-dogs-on-leash") 
                                     (NO_SMOKING . "no-smoking")
                                     (NO_ACCESS . "no-access")
                                     (NO_ALC . "no-alcohol") 
                                     (NO_LITTERING . "no-littering")
                                     (NO_DOGS . "no-dogs"))
  "text labels used to generate data description")


(defun resolve-pathname (dir file &optional type)
  "determines pathname for some input file under the concept subfolder"
  (let ((pn (if type 
              (merge-pathnames (make-pathname :directory (list :relative "concept" dir) :name file :type type)
                               *main-dir*)
              (merge-pathnames (make-pathname :directory (list :relative "concept" dir) :name file)
                               *main-dir*))))
    ;;(assert (probe-file pn))
    pn))

(defun write-kml (file contour name)
  (let* ((string-of-coordinates (with-output-to-string (str)
                                  (loop for c in (butlast contour) do
                                    (format str "~f,~f  " (imagpart c) (realpart c))
                                    finally (format str "~f,~f" (imagpart (car (last contour))) (realpart (car (last contour)))))))
         (kml `(("kml" . "http://www.opengis.net/kml/2.2") NIL
                (("Document" . "http://www.opengis.net/kml/2.2") NIL
                 (("open" . "http://www.opengis.net/kml/2.2") NIL "false")
                 (("Placemark" . "http://www.opengis.net/kml/2.2") NIL
                  (("name" . "http://www.opengis.net/kml/2.2") NIL ,name)
                  (("Polygon" . "http://www.opengis.net/kml/2.2") NIL
                   (("extrude" . "http://www.opengis.net/kml/2.2") NIL "true")
                   (("outerBoundaryIs" . "http://www.opengis.net/kml/2.2") NIL
                    (("LinearRing" . "http://www.opengis.net/kml/2.2") NIL
                     (("coordinates" . "http://www.opengis.net/kml/2.2") NIL
                      ,string-of-coordinates)))))))))
    (with-open-file (out file :direction :output :if-exists :supersede)
      (xmls:write-xml kml out))))

(defun get-kml-polygon (path)
  "returns a polygon as list of complex numbers from a KML file"
  (let* ((kml-tree (with-open-file (kml path)
		     (xmls:parse kml)))
	 ;; once the KML is parsed we to unwrap the overly complex structure of nasty from a nasty XML document...
	 (doc (find-if #'(lambda (x) (and (consp x) (consp (car x)) (equal (caar x) "Document"))) kml-tree))
	 (pm  (find-if #'(lambda (x) (and (consp x) (consp (car x)) (equal (caar x) "Placemark"))) doc))
	 (po  (find-if #'(lambda (x) (and (consp x) (consp (car x)) (equal (caar x) "Polygon"))) pm))
	 (ob  (find-if #'(lambda (x) (and (consp x) (consp (car x)) (equal (caar x) "outerBoundaryIs"))) po))
	 (lr  (find-if #'(lambda (x) (and (consp x) (consp (car x)) (equal (caar x) "LinearRing"))) ob))
	 (co  (third (find-if #'(lambda (x) (and (consp x) (consp (car x)) (equal (caar x) "coordinates"))) lr))))
    (assert (stringp co)) ; should be string of longitudes/latitudes
    (let ((coordinates ()))
      (with-input-from-string (in (substitute #\Space #\, co)) ; read from string, replacing ',' by space first
	(loop while (listen in) do
	     (let ((lon (read in nil nil)))
	       (when lon
		 (when (eq 0 lon) ; Google Earth produces a height value which is (hopefully always) 0 in our test data. We need to skip that
		   (setq lon (read in nil nil)))
		 (when lon
		     (let ((lat (read in nil nil)))
		       (assert (and (realp lat) (realp lon)))
		       (push (complex lat lon) coordinates)))))))
      (nreverse coordinates))))

(defun number-string? (string)
  (multiple-value-bind (n chs) (read-from-string string nil nil)
    (if (and (realp n) 
	     (= chs (length string)))
	n)))

(defun symbolify (string)
  "converts a string into a symbol, avoiding nasty characters"
  (labels ((tosymb (string)
	     (let ((cleaned-string (with-output-to-string (str)
				     (loop for c across string do
					  (if (find c ": #|\\ßäöüÄÖÜ./éèÈÉáà-!?+;'\"") ; list of nasty characters to zap, add more if necessary
					      (write-char #\X str)
					      (write-char (char-upcase c) str))))))
	       (or (number-string? cleaned-string)
		   (intern (if (digit-char-p (char cleaned-string 0)) ; Prolog doesn't like symbols to start with a digit, so we put a 'z' in front
                             (concatenate 'string "Z" cleaned-string)
                             cleaned-string)))))
	   (prefix (string)
	     (let ((p (position #\, string))) 
	       (if p (subseq string 0 p) string))))
    (if (find #\, string)
	(mapcar #'tosymb
		(loop 
		   for str = string then (let ((p (position #\, str))) (if p (subseq str (+ p 1)) "")) 
		   for nxt = (prefix str) then (prefix str)
		   until (equal str "") 
		   collect nxt))
	(tosymb string))))
  
(defstruct node
  id        ;; Integer   : the id given in OSM
  location  ;; Complex   : geo-coordinate
  tags)     ;; Assoc list: key-value-pairs from OSM's tag entries

(defun node-map (map-tree)
  "builds a hashmap from the node out of a map-tree"
  (let ((ht  (make-hash-table :size (round (* .75 (length map-tree)))))
        (nodes ())
        (cnt-tags 0)
        (cnt 0))
    (dolist (obj map-tree)
      (when (and (listp obj)
		 (equal (car obj) "node"))
	(let* ((atrs (find-if #'(lambda (x) (and (listp x) (listp (car x)))) (cdr obj)))
	       (lon (read-from-string (second (assoc "lon" atrs :test #'equal))))
	       (lat (read-from-string (second (assoc "lat" atrs :test #'equal))))
	       (id  (read-from-string (second (assoc "id" atrs :test #'equal))))
               (tags (remove-if-not #'(lambda (x) (and (listp x) (equal (car x) "tag"))) obj)))
	  (assert (and (realp lon) (realp lat)))
	  (setf (gethash id ht) (complex lat lon))
          (when tags
            (push (make-node :id id
                             :location (complex lat lon)
                             :tags (loop for kv in tags 
                                     collecting (let ((key (second (assoc "k" (second kv) :test #'equal))) 
                                                      (value (second (assoc "v" (second kv) :test #'equal)))) 
                                                  (cons (symbolify key) (symbolify value)))))
                  nodes)
            (incf cnt-tags))
	  (incf cnt))))
    (format t "~&;; ~a nodes read~%;; ~a nodes are tagged" cnt cnt-tags)
    (values nodes ht)))

(defstruct way
  id      ;; Integer   : the id given in OSM
  nodes   ;; List      : nodes as complex numbers #c(lon lat)
  tags)   ;; Assoc list: key-value pairs from OSM's tag entries

(defun setup-way (osm-way-node node-table)
  "sets up a way struct form an osm sub-tree"

  (make-way :id  (read-from-string (second (assoc "id" (find-if #'(lambda (x) (and (listp x) (listp (car x)))) osm-way-node) :test #'equal)))
	    :nodes (loop for ntag in osm-way-node when (and (listp ntag) (equal (car ntag) "nd")) collecting
			(gethash (read-from-string (second (first (second ntag)))) node-table))
	    :tags (loop for kvtag in osm-way-node when (and (listp kvtag) (equal (car kvtag) "tag")) collecting
		       (let ((kvs (second kvtag)))
			 (cons (symbolify (second (assoc "k" kvs :test #'equal))) 
			       (symbolify (second (assoc "v" kvs :test #'equal))))))))

(defvar *cached-mapfile* () ; declared globally as var to be persistent across re-compilation
  "pathname of recently parsed OSM file and its corresponding list of ways")

(defun osm-objects (path)
  (declare (special *cached-mapfile*))
  (if (equal path (car *cached-mapfile*))
      (cdr *cached-mapfile*)
    (let ((map-tree (with-open-file (osm path)
                      (format t "~&;; parsing OSM map file ~a~%" (pathname-name path))
                      (xmls:parse osm))))
      (multiple-value-bind (nodes ht) (node-map map-tree)
        (let ((objects (nconc nodes
                              (loop for obj in map-tree when (and (listp obj) (equal "way" (car obj))) collecting
                                (setup-way obj ht)))))
          (setf *cached-mapfile* (cons path objects))
          (format t "~&;; ~a objects in map~%" (length objects))
         objects)))))

(defgeneric distance (obj1 obj2))

(defmethod distance ((p complex) (q complex))
  (let* ((delta (- p q)) ;; www.movable-type.co.uk/scripts/latlong.html
	 (dlat  (/ (* pi (realpart delta)) 180.0))
	 (dlon  (/ (* pi (imagpart delta)) 180.0))
	 (a     (+ (expt (sin (* dlat .5)) 2)
		   (* (cos (/ (* pi (realpart p)) 180.0))
		      (cos (/ (* pi (realpart q)) 180.0))
		      (expt (sin (* dlon .5)) 2))))
	 (c     (* 2 (atan (sqrt a) (sqrt (- 1 a))))))
    (* c 6371000.0)))

(defun interpolate-way-nodes (nodes &optional (step 10))
  "puts intermediate stops into a sequence of nodes to not exceed a maximum distance inbetween two"
  (let ((dense-nodes (list (first nodes))))
    (loop for n in (cdr nodes) do
      (let ((d (distance (car dense-nodes) n)))
        (if (> step d)
          (push n dense-nodes)
          (let ((n1 (car dense-nodes))
                (s  (ceiling d step)))
            (loop for i from 1 to s do
              ;(format t "~% n=~a, i/s = ~a/~a   (-n n1) = ~a~%" n i s (- n n1))
              (push (+ n1 (* i (/ (- n n1) s))) dense-nodes))))))
    (nreverse dense-nodes)))

(defmethod distance ((p complex) (w way)) ;; wuester Hack, aber solange waypoint nahe genug beisammen liegen....
  (reduce #'(lambda (mindist q)
	      (min mindist (distance p q)))
	  (rest (interpolate-way-nodes (way-nodes w)))
	  :initial-value (distance p (first (way-nodes w)))))

(defmethod distance ((w way) (p complex))
    (distance p w))

(defmethod distance ((w1 way) (w2 way))
  (let ((w1s (interpolate-way-nodes (way-nodes w1))))
    (reduce #'(lambda (mindist q)
                (min mindist (distance q w2)))
            (rest w1s)
            :initial-value (distance (first w1s) w2))))
                    

(defmethod distance ((p complex) (n node))
  (distance p (node-location n)))

(defmethod distance ((n node) (p complex))
  (distance p (node-location n)))

(defmethod distance ((w way) (n node))
  (distance (node-location n) w))

(defmethod distance ((n node) (w way))
  (distance (node-location n) w))

(defmethod distance ((n node) (n2 node))
  (distance (node-location n) (node-location n2)))




(defgeneric entity-id (obj))

(defmethod entity-id ((w way))
  (way-id w))

(defmethod entity-id ((n node))
  (node-id n))

(defgeneric entity-tags (obj))

(defmethod entity-tags ((w way))
  (way-tags w))

(defmethod entity-tags ((n node))
  (node-tags n))

(defun scalar-product (c1 c2)
  (+ (* (realpart c1) (realpart c2))
     (* (imagpart c1) (imagpart c2))))

(defun left-normal (c)
  (complex (- (imagpart c)) (realpart c)))

(defun winding-number (coordinates)
  "determines whether closed path is oriented in clock-wise (-1) or counter-clockwise (+1) manner"
  (let ((p1 (first coordinates))
        (p2 (second coordinates))
        (p3 (third coordinates)))
    (signum (scalar-product (- p3 p2) (left-normal (- p2 p1))))))

(defun convex-hull (nodes)
  "Graham's scan algorithm for computing convex hull of a set of vertices"
  (let* ((p0 (reduce #'(lambda (minp p)
                         (if (or (< (realpart minp) (realpart p))
                                 (and (= (realpart minp) (realpart p))
                                      (< (imagpart minp) (imagpart p))))
                           minp
                           p))
                     (cdr nodes) 
                     :initial-value (car nodes)))
         (ps (sort (remove p0 nodes) #'< :key #'(lambda (x) (phase (- x p0)))))
         (hull (list (first ps) p0)))
    (loop for p in (cdr ps) do
      (loop while (= -1 (winding-number (list (second hull) (first hull) p))) do
        ;(format t "popping ~a~%" (car hull))
        (pop hull))
      ;(format t "pushing ~a~%" p)
      (push p hull))
    (nreverse hull)))

(defun node-in-way? (node way)
  "point-in-polygon test for convex polygons (fixme)"
  (and (cddr (way-nodes way))
       (let* ((way-nodes (convex-hull (way-nodes way)))
              (wn (winding-number way-nodes)))
         ;(format t "winding-number: ~a~%" wn)
         (do ((cs (append way-nodes (list (first way-nodes))) (cdr cs)))
             ((null (cdr cs))
              t)
           (unless (= (first cs) (second cs))
             (let ((x (scalar-product (- (node-location node) (second cs)) (left-normal (- (second cs) (first cs))))))
               ;(format t "~a -> ~a :: ~a  ~a ~%" (first cs) (second cs) (= (first cs) (second cs)) x)
               (if (< wn 0)
                 (when (> x 0) (return-from node-in-way? nil))
                 (when (< x 0) (return-from node-in-way? nil)))))))))

(defun merge-nodes-with-ways (objects)
  "aims to identify nodes corresponding to way entities, merging there tag attributes and removing the node"
  (let ((nodes (remove-if-not #'node-p objects))  ;; Knoten
        (del-nodes ())                            ;; zu löschende, da verschmolzene Knoten
        (ways  (remove-if-not #'way-p objects)))  ;; Wege
    (format t "~&;; considering ~a ways * ~a nodes for merging..." (length ways) (length nodes))
    (loop for n in nodes do
      (let ((additions ())  ;; Wege mit denen Knoten n verschmolzen werden soll
            (closest-way-dist 1000.0))
        (loop for w in ways do
          (if (and (> 1.0 (distance (first (way-nodes w)) (car (last (way-nodes w)))))
                   (node-in-way? n w))
            (progn ;; always merge node with surrounding polygon
              (setf closest-way-dist -1) ; damit keine vermeintlich näheren Knoten in Betracht gezogen werden
              (push w additions))            
            (let ((dist (distance w (node-location n))))
              (when (< dist 3.0)
                (cond ((< dist closest-way-dist) 
                       (setq closest-way-dist dist
                             additions (list w)))
                      ((< dist (- closest-way-dist 0.1)) ;; quasi gleich-weit
                       (push w additions)))))))
        (when additions
          (format t "~&;; merging node tags of node ~a into ways ~a" (node-id n) (mapcar #'way-id additions))
          (dolist (w additions)
            (setq ways (cons (make-way :id (way-id w) :nodes (way-nodes w) :tags (append (way-tags w) (node-tags n)))
                             (delete w ways)))))))
    #|
    (loop for w in ways do
      (let ((additions ()))
        (loop for n in nodes when (or (> 3.0 (distance w (node-location n)))
                                      (and (> 1.0 (distance (first (way-nodes w)) (car (last (way-nodes w)))))
                                           (node-in-way? n w))) do
          (format t "~&;; merging ~a with ~a" (way-id w) (node-id n))
          (push n additions)
          (push n del-nodes))
        (when additions
          (push w del-ways)
          (push (make-way :id (way-id w) :nodes (way-nodes w) :tags (append (way-tags w)
                                                                            (apply #'append (mapcar #'node-tags additions))))
                new-ways))))
    |#
    (format t "~&;; done merging")
    (nconc ways (nset-difference nodes del-nodes))))

(defun write-prolog-object-file (restriction d.objs)
  "generates a prolog source file describing a restriction in context of nearby objects"
  (with-open-file (out (merge-pathnames (make-pathname :directory (list :relative "newReasoner") :name "prolog-scene" :type "pl")
                                        *main-dir*)
                       :direction :output :if-exists :supersede)
    ;; specify sign of interest
    (format out "restriction([~(~{~a,~}~a]~)).~%" (butlast restriction) (car (last restriction)))
    ;; specify ids of objects nearby
    (let ((ids (mapcar #'(lambda (d.o) (entity-id (cdr d.o))) d.objs)))
      (format out "entities([~(~{~a,~}~a]~)).~%" (butlast ids) (car (last ids))))
    ;; specify distances to objects nearby
    (loop for (d . e) in d.objs do
      (format out "distance(~a, ~a).~%" (entity-id e) d))
    ;; specify distances among objects nearby
    (loop for (d1 . e) in d.objs do
      (loop for (d2 . e2) in d.objs when (not (eq e e2)) do
        (let ((d (distance e e2)))
          (when (<= d 10.0)
            (format out "obj_distance(~a,~a,~a).~%" (entity-id e) (entity-id e2) (if (< d 0.1) "touch" "near"))))))
    ;; specify properties of objects
    (loop for (d . e) in d.objs do
      (format out "has(~(~a, type, ~a~)).~%" (entity-id e) (type-of e))
	 (loop for (key . value) in (entity-tags e) do
	      (if (listp value)
		  (format out "has(~(~a, ~a, [~{~a,~} ~a]~)).~%" (entity-id e) key (butlast value) (car (last value)))
		  (format out "has(~(~a, ~a, ~a~)).~%" (entity-id e) key value))))))

(defun run-prolog ()
  "invokes SWI prolog on inference engine and object file, reading back the results written to the tmp file"
  (let ((outfile "/tmp/prolog-out.txt"))
  (when (probe-file outfile)
    (delete-file outfile))
    (format t ";; process output: ~a~%"
            (with-output-to-string (stream) 
              (format t "~&;; prolog process: ~a~%"
                      (run-program *swi-path* (list "-q"  ; quiet
                                                    "-t"  ; target (= evaluation goal)
                                                    "halt" ; (resolve-pathname "newReasoner" "prolog-out" "txt"))
                                                    "-g"
                                                    "interpret"
                                                    ;"-l"  ; files to load
                                                    (format nil "~a" (merge-pathnames (make-pathname :directory (list :relative "newReasoner") :name "prolog-scene" :type "pl")
                                                                                      *main-dir*))
                                                    (format nil "~a" (merge-pathnames (make-pathname :directory (list :relative "newReasoner") :name "inferenceEngine" :type "pl")
                                                                                      *main-dir*))
                                                    )
                                   :output stream)))) 
    ;; OS should wait until process is finished, but OS does file I/O sometimes asynchronously so we wait if necessary
    (dotimes (i 10)
      (when (probe-file outfile)
        (with-open-file (in outfile)
          (return-from run-prolog (read in))))
      (sleep 0.1))))

 

(defun object-polygon (obj)
  (assert obj (obj) "Kein Polygon fuer Objekt-ID '~a'" obj)
  (if (way-p obj) 
    (let ((wn (way-nodes obj)))
      (if (cddr wn)
        (if (> 0.0001 (abs (- (first wn) (car (last wn))))) ;; geschlossener Weg?
          wn
          (way-polygon wn))
        (let ((ortho (cis (+ (* 0.5 pi) (phase (- (first wn) (second wn))))))) ;; nur ein Wegsegment --> flächiges Polygon draus machen
          (list (- (first wn) (* 0.000015 ortho))
                (+ (first wn) (* 0.000015 ortho))
                (+ (second wn) (* 0.000015 ortho))
                (- (second wn) (* 0.000015 ortho))))))                
    ;; Ein Knoten --> Region drumherum machen
   #| (list (+ (node-location obj) #c(-0.00001 -.00002))
          (+ (node-location obj) #c(0.00001 -.00002))
          (+ (node-location obj) #c(0.00001 .00002))
          (+ (node-location obj) #c(-0.00001 .00002))
          ;(+ (node-location obj) #c(-0.00001 -.00002))
          )
|#
    :node
    #|
    (list (+ (node-location obj) #c(-0.000001d0 -.000002d0))
          (+ (node-location obj) #c(0.000001d0 -.000002d0))
          (+ (node-location obj) #c(0.000001d0 .000002d0))
          (+ (node-location obj) #c(-0.000001d0 .000002d0))
          ;(+ (node-location obj) #c(-0.00000001d0 -.00000002d0))
          )
    |#
))

(defun minmax (vals &key (key nil key-p))
  (labels ((val (v)
             (if key-p (funcall key v) v)))
    (reduce #'(lambda (min.max v)
                (let ((vk (val v)))
                  (cons (min (car min.max) vk) (max (cdr min.max) vk))))
            vals
            :initial-value (cons (val (car vals)) (val (car vals))))))

(defun bounding-box (locations)
  (list (minmax locations :key #'realpart)
        (minmax locations :key #'imagpart)))

(defun may-overlap? (locs1 locs2)
  (destructuring-bind ((minx1 . maxx1) (miny1 . maxy1)) (bounding-box locs1)
    (destructuring-bind ((minx2 . maxx2) (miny2 . maxy2)) (bounding-box locs2)
      (and (or (<= minx1 minx2 maxx1) 
               (<= minx1 maxx2 maxx1)
               (<= minx2 minx1 maxx2)
               (<= minx2 maxx1 maxx2))
           (or (<= miny1 miny2 maxy1) 
               (<= miny1 maxy2 maxy1)
               (<= miny2 miny1 maxy2) 
               (<= miny2 maxy1 maxy2))))))

(defun write-poly (stream poly)
  (loop for p in (if (> 1e-6 (abs (- (car poly) (car (last poly))))) (cdr poly) poly) do
    (format stream "~,6f ~,6f " (realpart p) (imagpart p))))

(defun find-object (id scene)
  (let ((obj (find id scene :key #'entity-id)))
    (unless obj
      (warn "~&Objekt ID ~a not found in local scene!" id))
    (setq obj (find id (cdr *cached-mapfile*) :key #'entity-id))
    (assert obj () "Objekt ID not in map!")
    obj))

(defun rate-reply (candidate ground-truth scene dir location)
  (cond ((eq (car ground-truth) 'kml) (rate-reply candidate (list 'poly (get-kml-polygon (resolve-pathname dir (second ground-truth)))) scene dir location))
        ((eq candidate 'here) ; polygon um den Standord bauen
         (rate-reply (list 'poly (list (+ location #c(-0.0001 -.0002))
                                       (+ location #c(0.0001 -.0002))
                                       (+ location #c(0.0001 .0002))
                                       (+ location #c(-0.0001 .0002))
                                       ;(+ location #c(-0.0001 -.0002))
                                       ))
                     ground-truth
                     scene
                     dir
                     location))
        ((eq candidate 'popup)
         (let ((poly (popup-poly scene location)))
           (if poly
             (rate-reply (list 'poly (popup-poly scene location))
                         ground-truth
                         scene
                         dir
                         location)
             (rate-reply 'here
                         ground-truth
                         scene
                         dir
                         location))))
        ((eq (car ground-truth) 'id)  ;; the 'right' OSM object should be computed
         (if (integerp candidate)
           (if (= candidate (second ground-truth))
             1 ; bingo
             (rate-reply (list 'poly (object-polygon (find-object candidate scene))) ; verkehrtes Objekt? -> Vergleich der Polygone
                        ground-truth
                        scene
                        dir
                        location))
           (rate-reply candidate 
                       (list 'poly (object-polygon (find-object (second ground-truth) scene))) ; Keine ID als Kandidat? -> Vergleich der Polygone
                       scene
                       dir
                       location)))
        ((integerp candidate)
         (rate-reply (list 'poly (object-polygon (find-object candidate scene )))
                     ground-truth
                     scene
                     dir
                     location))

        ((and (consp candidate) (eq (car candidate) 'poly) (eq (car ground-truth) 'poly))
         (if (and (not (eq (second candidate) :node))
                  (may-overlap? (second candidate) (second ground-truth)))
           (let ((polyfile (merge-pathnames (make-pathname :directory (list :relative "newReasoner" "geometry") :name "polys" :type "txt") *main-dir*)))
             (with-open-file (polys polyfile :direction :output :if-exists :supersede)
               ;(format t "~%candidate poly : ~a~%" (second candidate))
               (write-poly polys (second candidate))
               (format polys "~%;~%")
               (write-poly polys (second ground-truth)))
             (with-open-file (out "/tmp/poly1.txt" :direction :output :if-exists :supersede)
               (dolist (p (second candidate))
                 (format out "~f ~f~%" (realpart p) (imagpart p))))
             (with-open-file (out "/tmp/poly2.txt" :direction :output :if-exists :supersede)
               (dolist (p (second ground-truth))
                 (format out "~f ~f~%" (realpart p) (imagpart p))))
             (let ((result (read-from-string (with-output-to-string (stream) 
                                               (run-program (merge-pathnames (make-pathname :directory (list :relative "newReasoner" "geometry") :name "comparePolys") *main-dir*) 
                                                            (list (format nil "~a" polyfile))
                                                          :output stream))
                                             nil nil)))
               ;(assert (and (realp result) (<= 0 result 1)))
               (unless (realp result)
                 (setq result 0))
               (assert (realp result))
               (min 1 (max 0 result))))
           0.0))
  
        (t (error "not implemented for candidate ~a and ground-truth ~a" candidate ground-truth))))

(defparameter *scene* ()
  "last scene used in evaluate-sign-interpretation")

(defun here-or-id (obj)
  (if (eq obj 'here)
    obj
    (entity-id obj)))

(defun evaluate-sign-interpretation (spec &key (top-n 5))
  "runs the whole evaluation thing on a single entry of our test data"
  (format t "~&;; evaluating ~w...~%" spec)
  (destructuring-bind (dir osm-file coordinate restriction ground-truth . rest) spec ; rest typicially will just contain the image
    (declare (ignore rest))
    (let ((nearby-objects (mapcar #'(lambda (c) (cons (distance c coordinate) c))
                                  (merge-nodes-with-ways (loop for candidate in (osm-objects (resolve-pathname dir osm-file)) 
                                                           for dist = 0.0 then (distance coordinate candidate)
                                                           when (> 40.0 dist) 
                                                           collect candidate)))))
      (format t "~&;; ~a objects in local scene" (length nearby-objects))
      (write-prolog-object-file (if (listp restriction) restriction (list restriction)) nearby-objects)
      (format t "~&;; calling Prolog...")
      (let ((best-candidates (run-prolog))
            (scene (mapcar #'cdr nearby-objects)))
        (setf *scene* scene)
        (format t "~2%;; best-candidates: ~a" best-candidates)
        (if (consp best-candidates)
          (let* ((top-1 (first best-candidates))
                 (top-s (cdr (butlast best-candidates (max 0 (- (length best-candidates) top-n)))))
                 (top-1-rating (cons (rate-reply (first top-1) ground-truth scene dir coordinate) (first top-1)))
                 (top-n-rating (reduce #'(lambda (best-val candidate)
                                           (if (eq 1 (car best-val)) ; optimum reached? -> skip computation
                                             best-val
                                             (let ((v (rate-reply (first candidate) ground-truth scene dir coordinate)))
                                               (format t "~%;; candidate=~a   --->  ~a" candidate v)
                                               (if (> v (car best-val))
                                                 (cons v (first candidate))
                                                 best-val))))
                                       top-s
                                       :initial-value top-1-rating))
                 (by-dist (mapcar #'cdr (sort nearby-objects #'< :key #'car)))
                 (nearest (rate-reply (here-or-id (first by-dist)) ground-truth scene dir coordinate))
                 (nearest-n (reduce #'(lambda (best-val candidate)
                                        (if (eq 1 best-val) ; optimum reached? -> skip computation
                                          best-val
                                          (max best-val (rate-reply (here-or-id candidate) ground-truth scene dir coordinate))))
                                    (loop for x in by-dist for i from 1 to top-n collecting x)
                                    :initial-value nearest)))
            (format t "~&;; nearest objects considered: ~a~%" (mapcar #'entity-id (loop for x in by-dist for i from 1 to top-n collecting x)))
            (unless (every #'(lambda (x) (<= 0.0 x 1.0))  (list (car top-1-rating) (car top-n-rating) nearest nearest-n))
              (error "rated replies outside 0...1 range!~%about to return:~a"  (list (car top-1-rating) (car top-n-rating) (first ground-truth) nearest nearest-n)))
            (values (car top-1-rating) (car top-n-rating) (first ground-truth) nearest nearest-n)))))))

(defun export-evaluation (results top-n)
    (let ((results-id-only (remove 'kml results :key #'third))
          (results-kml-only (remove 'id results :key #'third)))
      (with-open-file (res (merge-pathnames (make-pathname :directory (list :relative "concept" "paper" "content") :name "results" :type "tex") *main-dir*)
                           :direction :output :if-exists :supersede)

        (format res "% !TEX root = ../main.tex~2%% DO NOT EDIT THIS FILE -- IT IS GENERATED AUTOMATICALLY DURING EVALUATION~2%")
        (format res " \\begin{tabular}{l@{\\hspace*{4em}}l@{\\hspace*{2em}}l}~%test condition & nearest & semantic search\\\\ \\toprule {\\bf all ~a instances:}\\\\~%" (length results))
        (format res "avg. $F_1$ for top-1 & ~,2f (~,2f\\% $> 0$) & ~,2f (~,2f\\% $> 0$) \\\\~%" 
                (/ (reduce #'+ (mapcar #'fourth results)) (length results))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (fourth x))) results) (length results)))
                (/ (reduce #'+ (mapcar #'first results)) (length results))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (first x))) results) (length results))))
        (format res "avg. $F_1$ for best in top-~a & ~,2f (~,2f\\% $> 0$) & ~,2f (~,2f\\% $> 0$)\\\\~%" 
                top-n 
                (/ (reduce #'+ (mapcar #'fifth results)) (length results))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (fifth x))) results) (length results)))
                (/ (reduce #'+ (mapcar #'second results)) (length results))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (second x))) results) (length results))))

        (format res "\\midrule {\\bf ~a ID instances:}\\\\~%" (length results-id-only))
        (format res "avg. $F_1$ for top-1 & ~,2f (~,2f\\% $> 0$) & ~,2f (~,2f\\% $> 0$)\\\\~%" 
                (/ (reduce #'+ (mapcar #'fourth results-id-only)) (length results-id-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (fourth x))) results-id-only) (length results-id-only)))
                (/ (reduce #'+ (mapcar #'first results-id-only)) (length results-id-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (first x))) results-id-only) (length results-id-only))))
        (format res "avg. $F_1$ for best in top-~a& ~,2f (~,2f\\% $> 0$) & ~,2f (~,2f\\% $> 0$)\\\\~%" 
                top-n 
                (/ (reduce #'+ (mapcar #'fifth results-id-only)) (length results-id-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (fifth x))) results-id-only) (length results-id-only)))
                (/ (reduce #'+ (mapcar #'second results-id-only)) (length results-id-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (second x))) results-id-only) (length results-id-only))))
        (format res "correct ID as top-1  result & ~,2f\\% & ~,2f\\%\\\\~%" 
                (* 100 (/ (count 1.0 results-id-only :key #'fourth :test #'=) (length results-id-only)))
                (* 100 (/ (count 1.0 results-id-only :key #'first :test #'=) (length results-id-only))))
        (format res "correct ID in top-~a result & ~,2f\\% & ~,2f\\%\\\\~%" top-n 
                (* 100 (/ (count 1.0 results-id-only :key #'fifth :test #'=) (length results-id-only)))
                (* 100 (/ (count 1.0 results-id-only :key #'second :test #'=) (length results-id-only))))

        (format res "\\midrule {\\bf ~a KML instances:}\\\\~%" (length results-kml-only))
        (format res "avg. $F_1$ for top-1 & ~,2f (~,2f\\% $> 0$) & ~,2f (~,2f\\% $> 0$)\\\\~%" 
                (/ (reduce #'+ (mapcar #'fourth results-kml-only)) (length results-kml-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (fourth x))) results-kml-only) (length results-kml-only)))
                (/ (reduce #'+ (mapcar #'first results-kml-only)) (length results-kml-only))
                (* 100(/ (count-if #'(lambda (x) (< 0 (first x))) results-kml-only) (length results-kml-only))))
        (format res "avg. $F_1$ for best in top-~a & ~,2f (~,2f\\% $> 0$) & ~,2f (~,2f\\% $> 0$)\\\\~%" 
                top-n 
                (/ (reduce #'+ (mapcar #'fifth results-kml-only)) (length results-kml-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (fifth x))) results-kml-only) (length results-kml-only)))
                (/ (reduce #'+ (mapcar #'second results-kml-only)) (length results-kml-only))
                (* 100 (/ (count-if #'(lambda (x) (< 0 (second x))) results-kml-only) (length results-kml-only))))
        (format res "\\bottomrule~%\\end{tabular}"))))

(defun run-evaluation (&key (top-n 5))
  "runs evaluation and creates summary report"
  (let ((results (loop for spec in *evaluation* collecting (append (multiple-value-list (evaluate-sign-interpretation spec :top-n top-n))
                                                                   (last spec)))))
    (let ((results-id-only (remove 'kml results :key #'third))
          (results-kml-only (remove 'id results :key #'third)))
      (format t "~2%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
      (format t "~%;;; RESULTS FOR ALL SIGNS  ;;;")
      (format t "~%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
      (format t "~%AVERAGE F-MEASURE FOR TOP-1 : ~f" (/ (reduce #'+ (mapcar #'first results)) (length results)))
      (format t "~%AVERAGE F-MEASURE FOR TOP-~a : ~f" top-n (/ (reduce #'+ (mapcar #'second results)) (length results)))      
      
      (format t "~2%;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
      (format t "~%;;; RESULTS FOR ID ONLY  ;;;")
      (format t "~%;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
      (format t "~%AVERAGE F-MEASURE FOR TOP-1 : ~f" (/ (reduce #'+ (mapcar #'first results-id-only)) (length results-id-only)))
      (format t "~%AVERAGE F-MEASURE FOR TOP-~a : ~f" top-n (/ (reduce #'+ (mapcar #'second results-id-only)) (length results-id-only)))      
      (format t "~%CORRECT ID AS TOP-1         : ~a out of ~a" (count 1.0 results-id-only :key #'first :test #'=) (length results-id-only))
      (format t "~%CORRECT ID AS TOP-~a         : ~a out of ~a" top-n (count 1.0 results-id-only :key #'second :test #'=) (length results-id-only))
 
      (format t "~2%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
      (format t "~%;;; RESULTS FOR KML ONLY  ;;;")
      (format t "~%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
      (format t "~%AVERAGE F-MEASURE FOR TOP-1 : ~f" (/ (reduce #'+ (mapcar #'first results-kml-only)) (length results-kml-only)))
      (format t "~%AVERAGE F-MEASURE FOR TOP-~a : ~f" top-n (/ (reduce #'+ (mapcar #'second results-kml-only)) (length results-kml-only))))
    
    (format t "~2%---> evaluate (export-evaluation * ~a) for creating the tex result tables" top-n)
    results))

(defun describe-evaluation-data ()
  (with-open-file (dfig (merge-pathnames (make-pathname :directory (list :relative "concept" "paper" "content") :name "data-overview" :type "tex")
                                         *main-dir*)
                        :direction :output
                        :if-exists :supersede)
    (let* ((signs (apply #'append (mapcar #'fourth *evaluation*)))
           (sorted-signs (sort (remove-duplicates signs) #'< :key #'(lambda (s) (count s signs))))
           (sorted-sign-labels (mapcar #'(lambda (x) (cdr (assoc x *prohibition-labels*))) sorted-signs)))
    (format dfig "% !TEX root = ../main.tex
%% DO NOT EDIT THIS FILE -- CONTENT GENERATED AUTOMATICALLY BY REASONSER, FUNCTION DESCRIBE-EVALUATION-DATA!
\\begin{tikzpicture}
  \\begin{axis}[
    scale=0.7,
    xbar, xmin=0,
    width=5.5cm, height=~acm, enlarge y limits=0.05, enlarge x limits={abs=15pt,upper},
    tick label style={font=\\tiny\\scriptsize},
    bar width = 1.5ex,
    xlabel={\\# occurances},
    symbolic y coords={~{~a,~}~a},
    ytick=data,
    nodes near coords, nodes near coords align={horizontal},
    ]
    \\addplot coordinates {~{~a ~}};
  \\end{axis}
\\end{tikzpicture}
"
            (+ 1.5 (round (length sorted-signs) 2)) ; hoehe des plots
            (butlast sorted-sign-labels) (car (last sorted-sign-labels))
            (mapcar #'(lambda (s)
                        (format nil "(~a,~a)" (count s signs) (or (cdr (assoc s *prohibition-labels*)) (error "missing label for sign ~a" s))))
                    sorted-signs)
            
            )
      (format dfig "~&\\hfill~%\\includegraphics[height=~acm]{content/map.pdf}~%" (* .7 (+ 1.5 (round (length sorted-signs) 2))))
       (format dfig "\\caption{\\label{fig:testdata}Overview of the ~a instances of test data collected for evaluation (note: multiple prohibitions per sign can occur) and their geographic distribution (dot size demarcates relative distribution)}" (length *evaluation*)))
    ))

;;;
;;; Clustering von Schildpositionen für schicke Kartendarstellung
;;;

(defun least (fn lst &optional null)
  "Geringstes Element bzgl. Massfunktion"
  (declare (optimize (speed 3)
                     (safety 0))
           (type function fn)
           (list lst))
  (if (null lst)
    null
    (let ((best (car lst))
          (opt  (funcall fn (car lst))))
      (declare (type real opt))
      (dolist (x (cdr lst) (values best opt))
        (let ((v (funcall fn x)))
          (declare (type real v))
          (when (< v opt)
            (setq best x
                  opt v)))))))

(defun most (fn lst &optional null)
  "Groesstes Element bzgl. Massfunktion"
  (multiple-value-bind (x opt) (least #'(lambda (x) (- (funcall fn x))) lst null)
    (if opt
      (values x (- opt))
      x)))

(declaim (inline abs2))
(defun abs2 (c)
  "|c|^2 von komplexen Zahlen c"
  (declare (type complex c)
           (optimize (speed 3) (safety 0) (debug 0)))
  (+ (expt (realpart c) 2)
     (expt (imagpart c) 2)))

(defun closest-circle (p circles max-rad)
  "sucht das Kreiscluster das am naechsten von p ist heraus"
  (declare (optimize (speed 3)))
  (let ((c (least #'(lambda (c)
                      (let ((d (abs2 (- p (first (first c))))))
                        (declare (type real d))
                        (max 0 (- d (second (first c))))))
                  circles)))
    (and c
         (if (< (abs (- (first (first c)) p)) (* 2 max-rad))
           c))))

(defun circle (points)
  "bestimmt Kreisparameter fuer eine Kreisscheibe die alle points ueberdeckt"
  (let ((xmin (realpart (first points)))
        (xmax (realpart (first points)))
        (ymin (imagpart (first points)))
        (ymax (imagpart (first points))))
    (dolist (p points)
      (let ((x (realpart p))
            (y (imagpart p)))
        (if (< x xmin)
          (setq xmin x)
          (if (> x xmax)
            (setq xmax x)))
        (if (< y ymin)
          (setq ymin y)
          (if (> y ymax)
            (setq ymax y)))))
    (let* ((e1 (complex xmin ymin))
           (center (* .5 (+ e1 (complex xmax ymax)))))
      (list center (abs (- center e1))))))

(defun greedy-cluster (data &key (max-rad 0.01))
  "berechnet die kreisfroemigen Cluster fuer Daten"
  (let ((circles ())
        (2process data))
    (labels ((add-circle (center radius pts)
               ;; Kreise vereinigen?
               (let ((2remove ()))
                 (dolist (c circles)
                   (destructuring-bind ((center2 radius2) pts2) c
                     (when (< (abs (- center center2)) (* 1.1 (+ radius radius2)))
                       (if (if (<= radius radius2)
                             (every #'(lambda (p) (<= (abs (- p center2)) radius2)) pts)
                             ;;(<= (+ radius (abs (- center center2))) radius2)
                             (every #'(lambda (p) (<= (abs (- p center)) radius)) pts2)
                             ;;<= (+ radius2 (abs (- center center2))) radius)
                             )
                         ;; verschlucken:
                         (let* ((new-points (nconc pts pts2))
                                (new-c (circle new-points)))
                           (push c 2remove)
                           (setq center (first new-c)
                                 radius (second new-c)
                                 pts new-points))
                         ;; vereinigen?
                         (let* ((new-pts (append pts pts2))
                                (new-c (circle new-pts))
                                (new-radius (second new-c))
                                (new-center (first new-c)))                           
                           (when (< new-radius max-rad)
                             (setq center new-center
                                   pts    new-pts
                                   radius new-radius
                                   2remove (cons c 2remove))))))))
                 (setq circles (cons (list (list center radius) pts) (nset-difference circles 2remove))))))

    (loop while 2process do
      (let* ((p (pop 2process))
             (c (closest-circle p circles max-rad)))
        (if c
          (let* ((pts (second c))
                 (new-points (cons p pts))
                 (new-c (circle new-points))
                 (new-center (first new-c))
                 (new-radius (second new-c)))
            (if (> max-rad new-radius) ;;(< (/ new-area (+ cnt 1)) density)
              ;; passt noch dazu:
              (progn
                (setq circles (delete c circles))
                (add-circle new-center new-radius new-points))
              ;; passt nicht mehr dazu:
              (push (list (list p .01) (list p)) circles)))
          ;; ganz neuer Kreis:
          (push (list (list p .01) (list p)) circles)))))
    (mapcar #'car circles)))

(defun map-sign-locations ()
  (let* ((cs (mapcar #'third *evaluation*))
         (lats (mapcar #'realpart cs))
         (lons (mapcar #'imagpart cs))
         (range (format nil "-R~a/~a/~a/~a"  ;; Bereich der Karte auswaehlen
                               (- (floor (apply #'min lons)) 5)
                               (+ (ceiling (apply #'min lons)) 5)
                               (- (floor (apply #'min lats)) 5)
                               (+ (ceiling (apply #'min lats)) 5))))
    ;; write X/Y data
    (with-open-file (pos "/tmp/xy.dat" :direction :output :if-exists :supersede)
      (loop for c in (greedy-cluster cs :max-rad 0.05) do        
        (format pos "~a  ~a ~a~%"  
                (imagpart (first c)) 
                (realpart (first c)) 
                (+ 0.3 (* 0.5 (/ (count-if #'(lambda (p)
                                              (< (abs2 (- (first c) p)) (second c)))
                                          cs)
                                (length cs))))
                )))
    ;; produce map
    (run-program (merge-pathnames (make-pathname :directory (list :relative "concept" "paper" "content") :name "makeMap" :type "sh") *main-dir*)
                 (list (format nil "~a" (merge-pathnames (make-pathname :directory (list :relative "concept" "paper" "content")) *main-dir*))
                       range))))

(defun print-bitmap (bm)
  (let ((x (array-dimension bm 0))
        (y (array-dimension bm 1)))
    (loop for j from 0 to (- y 1) do
      (format t "~%")
      (loop for i from 0 to (- x 1) do
        (format t "~a" (cdr (assoc (aref bm i j) '((0 . "  ")
                                                   (1 . "**")
                                                   (2 . "..")
                                                   (3 . "XX")))))))))

(defun render-line (sx sy ex ey bm &optional (width 2))
  "draws line into bitmap bm using Bresenham's algorithm"
  (labels ((mark! (x y)
             (loop for xx from (- x width) to (+ x width) do
               (loop for yy from (- y width) to (+ y width) do
                 (when (array-in-bounds-p bm xx yy)
                   (setf (aref bm xx yy) 2)))))
           (bresenham (ex ey setter) ;; here we can assume the line is to be drawn form 0/0 to ex/ey and ex>ey>0
             (let ((y 0) 
                   (e (round ex 2)))
               (loop for x from 0 to ex do
                 (funcall setter x y)
                 (decf e ey)
                 (when (> 0 e)
                   (incf y)
                   (incf e ex))))))
    (let ((dx (- ex sx))
          (dy (- ey sy)))
      (cond ((and (< 0 dx) (< 0 dy) (<= dy dx)) ;; Oktand I, flach
             (bresenham dx dy #'(lambda (x y) (mark! (+ sx x) (+ sy y)))))
            ((and (< 0 dx) (< 0 dy) (> dy dx)) ;; Oktand II, steil: spiegeln 
             (bresenham dy dx #'(lambda (x y) (mark! (+ sx y) (+ sy x)))))
            ((and (> 0 dx) (< 0 dy) (> dy (- dx))) ;; Oktand III, steil links oben
             (bresenham dy (- dx) #'(lambda (x y) (mark! (- sx y) (+ sy x)))))
            ((and (> 0 dx) (< 0 dy) (<= dy (- dx))) ;; Oktand IV, flach nach -X
             (bresenham (- dx) dy #'(lambda (x y) (mark! (- sx x) (+ sy y)))))
            ((and (> 0 dx) (> 0 dy)  (<= (- dy) (- dx))) ;; Oktand V, flach nach -X unten
             (bresenham (- dx) (- dy) #'(lambda (x y) (mark! (- sx x) (- sy y)))))
            ((and (> 0 dx) (> 0 dy) (> (- dy) (- dx))) ;; Oktand VI, steil nach - X unten
             (bresenham (- dy) (- dx) #'(lambda (x y) (mark! (- sx y) (- sy x)))))
            ((and (< 0 dx) (> 0 dy) (> (- dy) dx)) ;; Oktand VI, steil nach X unten           
             (bresenham (- dy) dx #'(lambda (x y) (mark! (+ sx y) (- sy x)))))
            ((and (< 0 dx) (> 0 dy) (<= (- dy) dx)) ;; Oktand VIII, flach nach X unten
             (bresenham dx (- dy) #'(lambda (x y) (mark! (+ sx x) (- sy y)))))
            ((= 0 dx)
             (loop for y from (min sy ey) to (max sy ey) do
               (mark! sx y)))
            ((= 0 dy)
             (loop for x from (min sx ex) to (max sx ex) do
               (mark! x sy)))
            (t (error "shouldn't have happend: sx = ~a,  sy = ~a,  ex = ~a,  ey = ~a" sx sy ex ey)))))
  bm)

(defun flood (x y bm &optional (pixel-value 1))
  "recursive floodfill algorithm"
  (when (and (array-in-bounds-p bm x y)
             (= 0 (aref bm x y)))
    (setf (aref bm x y) pixel-value)
    (mapc #'(lambda (xx yy)
              (when (and (array-in-bounds-p bm xx yy)
                         (= 0 (aref bm xx yy)))
                (flood xx yy bm)))
          (list (- x 1) (+ x 1) x       x      )
          (list y       y       (- y 1) (+ y 1)))))

(defun relevance (p q r)
  (labels ((dist (p1 p2)
             (sqrt (+ (expt (- (car p1) (car p2)) 2)
                      (expt (- (cdr p1) (cdr p2)) 2)))))
    (- (+ (dist p q) (dist q r))
       (dist p r))))

(defun simplify-contour (points threshold)
  "applies DCE to simplify a contour ((xi . xy) ...)"
  (if (null (cddr points))
    points
    (let ((zero-pts ())
          (p1 (first points))
          (p2 (second points)))
      (dolist (p3 (append points (list p1 p2)))
        (when (> 0.001 (relevance p1 p2 p3))
          (push p2 zero-pts))
        (setf p1 p2
              p2 p3))
      (let ((min-score 0)
            (min-point ())
            (contour (remove-if #'(lambda (x) (find x zero-pts :test #'equal)) points)))
        (loop while (and (< min-score threshold) (cddr contour)) do
          ;(format t "~%contour length = ~a" (length contour))
          (setq min-score threshold)
          (let ((p1 (first contour))
                (p2 (second contour)))
            (dolist (p3 (append contour (list p1 p2)))
              (let ((s (relevance p1 p2 p3)))
                (when (> min-score s)
                  (setq min-point p2
                        min-score s)))
              (setf p1 p2
                    p2 p3)))
          (when (and (< min-score threshold) (cddr contour))
            ;(format t "~%removing  ~a @ score=~a" min-point min-score)
            (setf contour (remove min-point contour :test #'equal))))
        contour))))

(defun trace-poly (x y map)
  (let* ((xx (loop for x0 from x downto 0 finally (return 0) do
               (when (/= 1 (aref map x0 y))
                 (return (+ x0 1)))))
         (yy y)
         (x0 xx)
         (y0 yy)
         (dx 0)
         (dy -1)
         (contour (list (cons xx yy))))
    ;(format t "~%Startpunkt: x=~a y=~a~%" xx yy)
    ;; startrichtung bestimmen
    (loop for try from 0 to 3 finally (return-from trace-poly nil) do
      (let ((x+ (+ xx dx))
            (y+ (+ yy dy)))
        (when (and (array-in-bounds-p map x+ y+)
                   (= 1 (aref map x+ y+)))
          (return))
        (rotatef dx dy) ; drehen
        (setf dx (- dx))))
    ;(format t "~%Startrichtung: dx=~a dy=~a~%" dx dy)
    (incf xx dx)
    (incf yy dy)
    (push (cons xx yy) contour)
    (loop until (and (= x0 xx) (= y0 yy)) finally (return contour) do
      ;(format t "~%x=~a, y=~a,  dx=~a, dy=~a" xx yy dx dy)
      (let ((pixel-left (cons (+ xx dy) (+ yy (- dx)))))
        (cond ((and (array-in-bounds-p map (car pixel-left) (cdr pixel-left))
                    (= 1 (aref map (car pixel-left) (cdr pixel-left))))
               ;(print "drehe nach links und Schritt nach vorne...")
               (rotatef dx dy)
               (setf dy (- dy))
               (incf xx dx)
               (incf yy dy)
               (push (cons xx yy) contour))
              ((and (array-in-bounds-p map (+ xx dx) (+ yy dy))
                    (= 1 (aref map (+ xx dx) (+ yy dy))))
               ;(print "Schritt nach vorne")
               (incf xx dx)
               (incf yy dy)
               (push (cons xx yy) contour))
              (t ; nach rechts drehen
               (rotatef dx dy)
               (setf dx (- dx))
               ;(print "drehe nach rechts...")
               ))))))

(defparameter *map* nil
  "letzte Bitmap beim Bestimmen des Popup-Polygons")

(defparameter *popup* nil
  "letztes pop-up-poly")

(defun popup-poly (scene location)
  (let* ((m  40)
         (map (make-array (list (+ m m 1) (+ m m 1)) :initial-element 0)) ; 0: leer, 1: besetzt, 2: popup-poly
         (f1 50000.0)
         (f2 40000.0))
    (labels ((discretize (p)
               (let ((d (- p location)))
                 (cons (+ m (round (* f1 (realpart d))))
                       (+ m (round (* f2 (imagpart d))))))))
      ;; Alle Objektgrenzen in die Karte zeichnen
      (dolist (o scene)
        (when (way-p o)
          (let ((start (discretize (first (last (way-nodes o))))))
            (loop for node in (way-nodes o) do
              (let ((end (discretize node)))
                ;(format t "~%line from ~a to ~a" start end)
                (render-line (car start) (cdr start) (car end) (cdr end) map)
                (setq start end))))
          #|
          FIXME: dafür bräuchte es einen Punkt-in-Polygon-Test für beliebige (insb. konkave) Polygone
          ;; versuche, weg von Innen zu fuellen
          (let* ((mid (/ (reduce #'+ (way-nodes o)) (length (way-nodes o))))
                 (pixel (discretize mid)))
            (when (and (node-in-way? (make-node :location mid) o)
                       (array-in-bounds-p map (car pixel) (cdr pixel)))
              (format t "~%bitmap BEFORE filling:")
              (print-bitmap map)
              (flood (car pixel) (cdr pixel) map 2))
            (format t "~%bitmap AFTER filling:")
            (print-bitmap map)(break))
          |#
          ))
      (let ((seed ()))
        (loop for d from 0 to (- m 1) while (null seed) do
          (loop for x from (- m d) to (+ m d) do
            (when (= 0 (aref map x (+ m d)))
              (setq seed (cons x (+ m d)))
              (return))
            (when (= 0 (aref map x (- m d)))
              (setq seed (cons x (- m d)))
              (return)))
          (unless seed
            (loop for y from (- m -1 d) to (+ m -1 d) do ; Ecken nicht doppelt testen
              (when (= 0 (aref map (- m d) y))
                (setq seed (cons (- m d) y))
                (return))
              (when (= 0 (aref map (+ m d) y))
                (setq seed (cons (+ m d) y))
                (return)))))
        (if (null seed)
          (progn 
            (print "No seed found for pop-up region!")
            nil)
          (progn 
            (flood (car seed) (cdr seed) map)
            ;(setf (aref map (car seed) (cdr seed)) 3
            ;      (aref map 25 25) 3)
            ;(print-bitmap map)
            (setf *map* map)
            (let* ((pts (mapcar #'(lambda (p)
                                    (+ location (complex (/ (- (car p) m) f1) (/ (- (cdr p) m) f2))))
                                (simplify-contour (trace-poly (car seed) (cdr seed) map) 1.1))))
              ;(append (last pts) pts) ;; geschlossenes polygon
              (setf *popup* pts)
              (when pts
                (destructuring-bind ((minx . maxx) (miny . maxy)) (bounding-box pts)
                  (if (< 5.0 (distance (complex minx miny) (complex maxx maxy)))
                    pts
                    (object-polygon (make-node :location (* 0.5 (complex (+ minx maxx) (+ miny maxy))))))))
              )))))))

(defun way-polygon (open-path)
  "converts an open path into a closed way around the path"
  (destructuring-bind ((minx . maxx) (miny . maxy)) (bounding-box open-path)
    (let* ((m 50)
           (scale (/ m (max (- maxx minx) (- maxy miny))))
           (map (make-array (list (+ m m 1) (+ m m 1)) :initial-element 0))
           (mid (complex (* .5 (+ maxx minx)) (* .5 (+ maxy miny)))))
      ;(format t "~&;; way-polygon scale = ~a~%" scale)
      (labels ((discretize (p)
               (let ((d (- p mid)))
                 (cons (+ m (round (* scale (realpart d))))
                       (+ m (round (* scale (imagpart d))))))))
        
        (let ((start (discretize (first open-path))))
          (loop for node in (cdr open-path) do
            (let ((end (discretize node)))
              (render-line (car start) (cdr start) (car end) (cdr end) map 1) ; 1 Pixel breit
              (setq start end)))
          (dotimes (x (array-dimension map 0))
            (dotimes (y (array-dimension map 1))
              (when (eq 2 (aref map x y)) (setf (aref map x y) 1))))
          ;(setf *map* map)
          (mapcar #'(lambda (p)
                      (+ mid (complex (/ (- (car p) m) scale) (/ (- (cdr p) m) scale))))
                  (simplify-contour (trace-poly (car start) (cdr start) map) 0.75)))))))
        

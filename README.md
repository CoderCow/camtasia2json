# Camtasia2Json

Camtasia2Json ist ein Tool um spezielle Teile von Camtasia Studio Projektdateien (im XML Format) automatisiert in ein schlankes
und effizientes JSON Format zu transformieren, das dann von diversen webbasierten Playern konsumiert werden kann.

Neben einer reinen JSON transformation ermöglicht C2J es dem Videoautor dabei allerdings auch, zusätzliche "Metaelemente" in Camtasia Studio zu verwenden um die erzeugten JSON Daten mit weiteren nicht Camtasia spezifischen Daten anzureichern.
Welche Metaelemente in Camtasia Studio verwendet werden können ist in der Datei _Camtasia für Lernvideos und Educasts.docx_ beschrieben und Beispiele dazu finden sich in den Projektvorlagen.

Die Metaelemente dienen primär dem Zweck das Video mit weiteren interaktiven Funktionen für den Zuschauer anzureichern und es mehrsprachig zu machen. Natürlich muss der entsprechende Player, der die JSON Daten letztendlich konsumiert, diese interaktiven Funktionen nach dem C2J Vorgaben implementieren.

Player die das c2j Format teilweise unterstützen sind bspw.: c2j-player und ePlayer.

## Verwendung

Zur Ausführung ist das Java Runtime Environment (JRE) Version 8 erforderlich!

Rufen Sie die .jar Datei folgendermaßen auf, um eine Befehlsübersicht zu erhalten:
`java -jar CamtasiaToJson.jar /?`

## Technisches

Diese Anwendung ist in Java 8 geschrieben und liegt als ein IntelliJ IDEA 14 Projekt vor. Das Oracle XDK wird zur transformation der JSON Daten verwendet. Die XML Transformationen sind in den einzelnen _*.xsl_ Dateien definiert.

### Verwendete Bibliotheken

**Oracle XDK 10.1.0.2.0**

Zur Verarbeitung von XML und XSL.
Dokumentation:
* Xml Developer Kit Download: http://www.oracle.com/technetwork/database/index-100632.html
* Einleitung: https://docs.oracle.com/database/121/ADXDK/adx_overview.htm#ADXDK19014
* XSLT Processor: https://docs.oracle.com/database/121/ADXDK/adx_j_xslt.htm#ADXDK19219
* API Referenz: https://docs.oracle.com/database/121/JAXML/toc.htm

**jsoup 1.8.3**

Zum Parsen von HTML (für die Konvertierung von RTF zu HTML nützlich).
Dokumentation: http://jsoup.org/apidocs/

**jackson 2.6.2**

Zum Prüfen und Reformatieren von JSON.
Dokumentation: https://github.com/FasterXML/jackson-docs

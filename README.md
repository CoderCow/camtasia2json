# Camtasia2Json #

Camtasia2Json ist ein Tool um spezielle Teile von Camtasia Studio Projektdateien (im XML Format) automatisiert in ein schlankes
und effizientes JSON Format zu transformieren. Durch Nutzung der in Camtasia Studio gegebenen Features kann ein Autor somit
Videos produzieren und gleichzeitig zusätzliche interaktive Inhalte direkt im Autorentool definieren. Die Daten dieser interaktiven
Inhalte werden durch dieses Tool extrahiert und in eine JSON Datei transformiert die dann anschließend von webbasierten Playern,
wie bspw. dem ePlayer, verwendet werden kann, um so die Videos mit den entsprechenden zusätzliche interaktive Funktionen
abzuspielen.

Diese Anwendung ist in Java 8 geschrieben und liegt als ein IntelliJ IDEA 14 Projekt vor. JetBrains IntelliJ IDEA wird für die
Weiterentwicklung dieser Anwendung empfohlen, ist aber nicht zwingend erforderlich.

## Verwendung ##

Zur Ausführung ist das Java Runtime Environment (JRE) Version 8 erforderlich!

Rufen Sie die .jar Datei folgendermaßen auf, um eine Befehlsübersicht zu erhalten:
`java -jar CamtasiaToJson.jar /?`

## Abhängigkeiten ##

Das Projekt verwendet die folgenden Java-Bibliotheken:

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

## Lizenz ##

Das Projekt wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International" Lizenz von Creative Commons zur Verfügung
gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/
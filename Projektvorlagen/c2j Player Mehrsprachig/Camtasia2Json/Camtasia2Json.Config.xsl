<?xml version="1.0" encoding="UTF-8" ?>

<!--
  Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
  Lizenz von Creative Commons zur Verfügung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/

  Autor: David Kay Posmyk <KayPosmyk@gmx.de>
-->

<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsltUtil="http://www.oracle.com/XSL/Transform/java/de.hs_duesseldorf.medien.app.camtasia2json.XSLTUtil"
>
	<!-- ** Konstante Werte für die Ausgabedatei ** -->
	<xsl:variable name="OUTPUT_FILE_VERSION">1.1</xsl:variable>
	<xsl:variable name="GENERATOR_INFO">
		<xsl:text>Camtasia to JSON </xsl:text>
		<xsl:value-of select="xsltUtil:versionInfo()" />
	</xsl:variable>
	<!-- Kapitel haben nach ePlayer Formatvorlage ein "videoType" Attribut.
	     Da hier kein anderer Wert als "digital" bekannt ist wird dieser nur Konstant gesetzt. -->
	<xsl:variable name="CHAPTER_DEFAULT_VIDEO_TYPE">digital</xsl:variable>
	<xsl:variable name="DEFAULT_ID">1</xsl:variable>
	<xsl:variable name="DEFAULT_LANGUAGE">de</xsl:variable>

	<!-- ** Camtasia Studio Konstanten ** -->
	<!-- Die Version von Camtasia Studio Projektdateien die von diesem Tool unterstützt wird. -->
	<xsl:variable name="SUPPORTED_CAMTASIA_VERSION">8.00</xsl:variable>
	<xsl:variable name="CAMTASIA_FRAMERATE">30</xsl:variable>

	<!-- ** Konstanten der Zweckentfremdung ** -->
	<!-- Die Zeile die zur Zweckentfremdung in Camtasia Callouts den visuellen formatierbaren Inhalt von der Attributmenge trennt. -->
	<xsl:variable name="CALLOUT_TEXT_ATTRIBUTE_SEPARATOR">#!****</xsl:variable>

	<xsl:variable name="SPECIAL_TRACK_NAME_CONFIG">#!konfig</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_METADATA">#!meta</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_CATEGORIES">#!kategorien</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_CHAPTERS">#!kapitel</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_CHAPTER_EXTRAS">#!k-extras</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_NOTES">#!notizen</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_SUBTITLES">#!utitel</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_OVERLAYS">#!overlays</xsl:variable>
	<xsl:variable name="SPECIAL_TRACK_NAME_AUTHCAM">#!autkam</xsl:variable>

	<xsl:variable name="SPECIAL_GROUP_NAME_LINKLIST">#!linkliste</xsl:variable>
</xsl:stylesheet>
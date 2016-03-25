<?xml version="1.0" encoding="UTF-8" ?>

<!--
  Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
  Lizenz von Creative Commons zur Verfügung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/

  Autor: David Kay Posmyk <KayPosmyk@gmx.de>
-->

<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:c2jUtil="http://app.medien.hs-duesseldorf.de/camtasia2json/util"
	xmlns:xsltUtil="http://www.oracle.com/XSL/Transform/java/de.hs_duesseldorf.medien.app.camtasia2json.XSLTUtil"
>
	<!-- Projektmetadaten -->
	<xsl:variable name="projectFileVersion" as="xsd:string">
		<xsl:variable name="version" select="Project_Data/@Version" />

		<xsl:if test="not($version)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Die Versionsnummer der Camtasia Projektdatei konnte nicht ermittelt werden. Dieses Tool ist veraltet und benötigt ein Update.</xsl:text>
			</xsl:message>
		</xsl:if>
		<xsl:if test="$version != $SUPPORTED_CAMTASIA_VERSION">
			<xsl:message>
				<xsl:text>WARNUNG: Die Camtasia Projektdatei liegt in der Version "</xsl:text>
				<xsl:value-of select="$version" />
				<xsl:text>" vor. Dieses Tool ist für die Version "</xsl:text>
				<xsl:value-of select="$SUPPORTED_CAMTASIA_VERSION" />
				<xsl:text>" ausgelegt und benötigt ggf. ein Update.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:value-of select="$version" />
	</xsl:variable>
	<xsl:variable name="projectWidth" as="xsd:string" select="Project_Data/Project_Settings/ProjectWidth/text()" />
	<xsl:variable name="projectHeight" as="xsd:string" select="Project_Data/Project_Settings/ProjectHeight/text()" />

	<xsl:variable name="metaTitle" as="xsd:string">
		<xsl:variable name="value" select="//Project_MetaData_Object[FieldArrayKey=8]/Value/text()" />

		<xsl:if test="not($value)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Es wurde kein Titel für das Camtasia Projekt angegeben.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:value-of select="$value" />
	</xsl:variable>

	<xsl:variable name="metaCategory" as="xsd:int">
		<xsl:variable name="value" select="//Project_MetaData_Object[FieldArrayKey=10]/Value/text()" />

		<xsl:if test="not($value)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Es wurde keine Kategorie ID für das Camtasia Projekt angegeben.</xsl:text>
			</xsl:message>
		</xsl:if>
		<xsl:if test="not($value castable as xsd:int) or number($value) lt 0">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Die Kategorie "</xsl:text>
				<xsl:value-of select="$value" />
				<xsl:text>" des Camtasia Projekts muss eine positive nummer sein. </xsl:text>
				<xsl:text>Diese Nummer ist eine Referenz auf eine Kategorie in der globalen Konfigurationsdatei des Players.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:value-of select="number($value)" />
	</xsl:variable>

	<xsl:variable name="metaDate" as="xsd:string">
		<xsl:variable name="value" select="//Project_MetaData_Object[FieldArrayKey=13]/Value/text()" />

		<xsl:choose>
			<xsl:when test="not($value)">
				<xsl:message>
					<xsl:text>INFO: Es wurde kein Datum für das Camtasia Projekt angegeben. Das heutige Datum wird verwendet.</xsl:text>
				</xsl:message>
				<xsl:value-of select="xsltUtil:dateNow()" />
			</xsl:when>
			<xsl:otherwise>
				<!-- Typische Zeitangaben in Camtasia sind oft mit Datum und Uhrzeit versehen.  -->
				<xsl:variable name="dateComponent" select="substring-before($value, ' ')" />
				<xsl:value-of select="xsltUtil:convertDate($dateComponent, 'dd.MM.yyyy', 'yyyy-MM-dd')" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="metaLanguage" as="xsd:string">
		<xsl:variable name="value" select="//Project_MetaData_Object[FieldArrayKey=16]/Value/text()" />

		<xsl:choose>
			<xsl:when test="not($value)">
				<xsl:message>
					<xsl:text>INFO: Es wurde keine Sprache für das Camtasia Projekt angegeben. Es wird "</xsl:text>
					<xsl:value-of select="$DEFAULT_LANGUAGE" />
					<xsl:text>" verwendet</xsl:text>.
				</xsl:message>

				<xsl:value-of select="$DEFAULT_LANGUAGE" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="not(c2jUtil:validateLangCode($value))">
					<xsl:message>
						<xsl:text>WARNUNG: Der im Camtasia Projekt angegebene Sprachcode "</xsl:text>
						<xsl:value-of select="$value" />
						<xsl:text>" ist nicht RFC 1766 konform (bsp. für gültige Werte: "de", "en-US").</xsl:text>
					</xsl:message>
				</xsl:if>

				<xsl:value-of select="xsltUtil:lowerCase($value)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="metaTopic" select="//Project_MetaData_Object[FieldArrayKey=9]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaKeywords" select="//Project_MetaData_Object[FieldArrayKey=11]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaDescription" select="//Project_MetaData_Object[FieldArrayKey=12]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaFormat" select="//Project_MetaData_Object[FieldArrayKey=14]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaRessourceCode" select="//Project_MetaData_Object[FieldArrayKey=15]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaRelation" select="//Project_MetaData_Object[FieldArrayKey=17]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaSource" select="//Project_MetaData_Object[FieldArrayKey=18]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaRessourceType" select="//Project_MetaData_Object[FieldArrayKey=19]/Value/text()" as="xsd:string" />
	<xsl:variable name="metaCoverage" select="//Project_MetaData_Object[FieldArrayKey=20]/Value/text()" as="xsd:string" />

	<!-- Tracks in gut verarbeitbarem XML.
	     Strukturaufbau:
	      <Track ident="Trackname[en-US]" name="Trackname" lang="en-US" dur="123.12">
	      	<Media>
	      		... alle Medien des Tracks, siehe Template "transformMedium" ...
	      	</Media>
	      </Track>
	-->
	<xsl:variable name="transformedTracks">
		<xsl:variable name="tracks" select="//Timeline/GenericMixer/Tracks/GenericTrack" />

		<xsl:for-each select="$tracks">
			<xsl:variable name="ident" select="xsltUtil:lowerCase(Attributes/Attribute[@name = 'ident']/@value)" />
			<xsl:variable name="langRaw" select="substring-before(substring-after($ident, '['), ']')" />
			<xsl:variable name="hasLangCode" select="string-length($langRaw) gt 0" />
			<xsl:if test="$hasLangCode and not(c2jUtil:validateLangCode($langRaw))">
				<xsl:message terminate="yes">
					<xsl:text>FEHLER: Der im Track "</xsl:text>
					<xsl:value-of select="$ident" />
					<xsl:text>" angegebene Sprachcode ist nicht RFC 1766 konform (bsp. für gültige Werte: "de", "en-US").</xsl:text>
				</xsl:message>
			</xsl:if>

			<xsl:variable name="name" select="c2jUtil:substring-before($ident, '[')" />
			<xsl:variable name="lang" select="if ($hasLangCode) then $langRaw else $metaLanguage" />
			<xsl:variable name="transformedMedia">
				<xsl:for-each select="Medias/*">
					<xsl:call-template name="transformMedium">
						<xsl:with-param name="medium" select="." />
					</xsl:call-template>
				</xsl:for-each>
			</xsl:variable>

			<Track ident="{$ident}" name="{$name}" lang="{$lang}">
				<xsl:attribute name="dur">
					<xsl:value-of select="c2jUtil:max($transformedMedia/*/@end)" />
				</xsl:attribute>

				<Media>
					<xsl:copy-of select="$transformedMedia/*" />
				</Media>
			</Track>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="transformedConfigTrack" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_CONFIG]" />
	<xsl:variable name="transformedMetaTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_METADATA]" />
	<xsl:variable name="transformedCategoryTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_CATEGORIES]" />
	<xsl:variable name="transformedChapterTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_CHAPTERS]" />
	<xsl:variable name="transformedChapterExtraTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_CHAPTER_EXTRAS]" />
	<xsl:variable name="transformedNoteTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_NOTES]" />
	<xsl:variable name="transformedSubtitleTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_SUBTITLES]" />
	<xsl:variable name="transformedOverlayTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_OVERLAYS]" />
	<xsl:variable name="transformedAuthCamTracks" select="$transformedTracks/Track[@name = $SPECIAL_TRACK_NAME_AUTHCAM]" />

	<!-- Transformiert ein beliebiges Medium der Zeitleiste in auswertbare Xml-Daten die dann leicht für die JSON Transformation abgefragt
	     werden können.

	     Strukturaufbau:
	      <Medientyp id="1104" name="nur bei Gruppen" begin="0" dur="16.43" end="16.43" opacity="0 bis 1, nicht bei Captions" leftOpacityFadeDur="0" rightOpacityFadeDur="0">
	      	<Transformation>
	      		<Transformation type="scale" x="0" y="0" z="0" />
	      		<Transformation type="translation" x="0" y="0" z="0" />
	      		<Transformation type="rotation" x="0" y="0" z="0" />
	      		<Transformation type="shear" x="0" y="0" z="0" />
	      		<Transformation type="anchor" x="0" y="0" z="0" />
	      	</Transformations>
	      	<ContentData>
	      		<Html>
	      			Der Formatierbare Inhalt des Elements (über dem #!****) im HTML Format.
	      		</Html>
	      		<Attributes>
	      			<Attribute>
	      				<Attribute name="Titel" value="Allgemein"/>
	      			</Attribute>
	      		</Attributes>
	      	</ContentData>
	      	<CaptionData>
	      		<Caption relativeBegin="0" dur="5.5" relativeEnd="5.5" html="Hello" />
	      	</CaptionData>
	      	<SubMedia>
	      		<Medientyp>... selbe Daten (durch rekursion) ...</Medientyp>
	      	</SubMedia>
	      </Medientyp>
	-->
	<xsl:template name="transformMedium">
		<xsl:param name="medium" as="xsd:element" />
		<xsl:variable name="type" select="local-name($medium)" />
		<xsl:variable name="id" select="$medium/@id" />

		<xsl:element name="{$type}">
			<xsl:attribute name="id">
				<xsl:value-of select="$id" />
			</xsl:attribute>
			<xsl:attribute name="name">
				<!-- Hat normalerweise nur bei Medien vom typ Gruppe einen Wert. -->
				<xsl:value-of select="xsltUtil:lowerCase(MetaData/entry[@key = 'WinSubProjectDisplayName']/@val)" />
			</xsl:attribute>

			<xsl:variable name="begin" select="
				if ($medium/@start) then
					c2jUtil:framesToSeconds($medium/@start)
				else
					c2jUtil:framesToSeconds($medium/*[1]/@start)
			" />
			<xsl:variable name="dur" select="
				if ($medium/@duration) then
					c2jUtil:framesToSeconds($medium/@duration)
				else
					c2jUtil:framesToSeconds(c2jUtil:max($medium//@duration))
			" />

			<xsl:attribute name="begin">
				<xsl:value-of select="$begin" />
			</xsl:attribute>
			<xsl:attribute name="dur">
				<xsl:value-of select="$dur" />
			</xsl:attribute>
			<xsl:attribute name="end">
				<xsl:value-of select="format-number(number($begin) + number($dur), '#.##', 'en')" />
			</xsl:attribute>
			<xsl:attribute name="opacity">
				<xsl:value-of select="$medium/Parameters/InterpolatingParam[@name = 'opacity']/@value" />
			</xsl:attribute>

			<xsl:variable name="leftOpacityFadeDurRaw" select="$medium/LeftEdgeMods[@groupName = 'OpacityFade']/@length" />
			<xsl:variable name="rightOpacityFadeDurRaw" select="$medium/RightEdgeMods[@groupName = 'OpacityFade']/@length" />
			<xsl:attribute name="leftOpacityFadeDur">
				<xsl:value-of select="if (string-length($leftOpacityFadeDurRaw) gt 0) then c2jUtil:framesToSeconds($leftOpacityFadeDurRaw) else 0" />
			</xsl:attribute>
			<xsl:attribute name="rightOpacityFadeDur">
				<xsl:value-of select="if (string-length($rightOpacityFadeDurRaw) gt 0) then c2jUtil:framesToSeconds($rightOpacityFadeDurRaw) else 0" />
			</xsl:attribute>

			<!-- Die Größen sind in Pixeln angegeben, da diese Pixel aber relativ zu den Bearbeitungsmaße von Camtasia Studio sind und nicht unbedingt zur
			     Größe des Videos, sind sie für eine Playerimplementierung nutzlos - besonders weil dieser ein Video auch in mehreren Auflösungen abspielen
			     können soll. Daher müssen die Pixelangaben in Prozentwerte umgerechnet werden. -->
			<xsl:variable name="transformations">
				<xsl:call-template name="transformVectorParams">
					<xsl:with-param name="vectorParams" select="$medium/Transformer/*" />
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="scaleTransform" select="$transformations/Transformation[@type = 'scale']" />

			<xsl:variable name="vectorNode" select="$medium/Attributes/Attribute[@name = 'vectorNode']/VectorNode" />
			<xsl:if test="$vectorNode">
				<!-- Callouts besitzen eine Basisgröße, werden aber durch eine Skalierungs-Transformation zusätzlich vergrößert / verkleinert.
				     Diese Transformation bezieht sich allerdings nicht auf den Text selbst sondern nur auf das Vektorobjekt.
				     Dieses Verhalten würde sich einerseits schlecht durch einen Player implementieren lassen und andererseits auch keinen
				     sinn ergeben, da der Player seine eigenen Stile nutzt und Text normalerweise mitskalieren sollte. -->
				<xsl:variable name="baseWidth" select="number($vectorNode/DoubleParameters/InterpolatingParam[@name = 'width']/@value)" />
				<xsl:variable name="baseHeight" select="number($vectorNode/DoubleParameters/InterpolatingParam[@name = 'height']/@value)" />
				<xsl:if test="$baseWidth">
					<xsl:attribute name="width">
						<xsl:value-of select="c2jUtil:roundNumber((($baseWidth * number($scaleTransform/@x)) div number($projectWidth)) * 100)" />
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$baseHeight">
					<xsl:attribute name="height">
						<xsl:value-of select="c2jUtil:roundNumber((($baseHeight * number($scaleTransform/@y)) div number($projectHeight)) * 100)" />
					</xsl:attribute>
				</xsl:if>
			</xsl:if>

			<!-- Skalierungen der Größe und alle anderen Transformationen die Standardmäßig (Animationslos) immer auf das Medium
			     angewendet werden. -->
			<Transformations>
				<xsl:copy-of select="$transformations/Transformation[@type != 'scale']" />
			</Transformations>

			<xsl:variable name="rtfText" select="$vectorNode//Parameter[@name = 'text']/Keyframes/Keyframe[1]/@value" />
			<xsl:if test="$rtfText">
				<xsl:variable name="contentData" select="xsltUtil:camtasiaCalloutContentDataFromRtf($rtfText, $CALLOUT_TEXT_ATTRIBUTE_SEPARATOR)" />

				<!-- Als Inhaltsdaten bezeichnen wir den in HTML und in eine Attributliste konvertierten Textinhalt des Elements.
				     Die Trennung zwischen dem HTML text und der Attribute erfolgt dabei durch eine spezielle Sequenz wie in XSLTUtil definiert. -->
				<ContentData>
					<xsl:copy-of select="$contentData/Html" />
					<xsl:copy-of select="$contentData/Attributes" />
				</ContentData>
			</xsl:if>

			<!-- Untertiteldaten aufbereiten. -->
			<xsl:variable name="captionData" select="$medium/Parameters/Parameter[@name = 'captionData']/Keyframes" />
			<xsl:if test="$captionData">
				<xsl:variable name="duration" select="c2jUtil:framesToSeconds($medium/@duration)" />
				<xsl:variable name="mediaStartFrames" select="c2jUtil:normalizedFrames($medium/@mediaStart)" />

				<CaptionData>
					<xsl:for-each select="$captionData/Keyframe">
						<xsl:variable name="timeRaw" select="c2jUtil:normalizedFrames(@time)" />
						<xsl:variable name="relativeBegin" select="
							if (number($timeRaw - $mediaStartFrames) ge 0) then
								c2jUtil:framesToSeconds($timeRaw - $mediaStartFrames)
							else
								0
						" />
						<xsl:variable name="relativeEnd" select="
							if (following-sibling::Keyframe[c2jUtil:framesToSeconds(c2jUtil:normalizedFrames(@time) - $mediaStartFrames) lt number($duration)]) then
								c2jUtil:framesToSeconds(c2jUtil:normalizedFrames(following-sibling::Keyframe/@time) - $mediaStartFrames)
							else
								$duration
						" />

						<xsl:if test="number($relativeBegin) lt number($duration) and number($relativeEnd) gt 0">
							<!-- TODO: Minus 0.50 um Fehler bei der Untertitelanzeige im ePlayer zu verhindern, entfernen sobald ePlayer gefixt wurde. -->
							<xsl:variable name="duration" select="format-number($relativeEnd - $relativeBegin - 0.50, '#.##', 'en')" />

							<!-- Die beiden Zahlen am Anfang und Ende wegschneiden. -->
							<xsl:variable name="textValue" select="xsltUtil:replace(@value, '^\{\d+,|,\d+\}$', '')" />

							<!-- Untertiteltext können auch leicht Formatiert werden, daher ist ggf. eine RTF umwandlung erforderlich. -->
							<xsl:variable name="htmlValue" select="
								if (starts-with($textValue, '{\rtf')) then
									xsltUtil:rtfToHtml($textValue, false)
								else
									$textValue
							" />

							<Caption relativeBegin="{$relativeBegin}" dur="{$duration}" relativeEnd="{$relativeEnd}" html="{$htmlValue}" />
						</xsl:if>
					</xsl:for-each>
				</CaptionData>
			</xsl:if>

			<!-- Hotspot Informationen -->
			<xsl:variable name="hotspotInfo" select="$medium/ExtraData/Entry/HotspotInfo" />
			<xsl:if test="$hotspotInfo">
				<xsl:copy-of select="$hotspotInfo" />
			</xsl:if>

			<!-- Weitere Medien innerhalb diesem verarbeiten. Dies ist bei Gruppe-Medien der Fall. -->
			<xsl:variable name="subMedia" select="$medium/GenericMixer/Tracks/GenericTrack/Medias" />
			<xsl:if test="$subMedia">
				<SubMedia>
					<xsl:for-each select="$subMedia/*">
						<xsl:call-template name="transformMedium"> <!-- Rekursiver Aufruf -->
							<xsl:with-param name="medium" select="." />
						</xsl:call-template>
					</xsl:for-each>
				</SubMedia>
			</xsl:if>
		</xsl:element>
	</xsl:template>

	<!-- Transformiert eine Menge von VectorParameter Knoten in besser zu verarbeitendes XML. -->
	<xsl:template name="transformVectorParams">
		<xsl:param name="vectorParams" as="xsd:element*" />

		<xsl:for-each select="$vectorParams">
			<xsl:variable name="x" select="
				if (@name='translation') then
					c2jUtil:roundNumber((number(InterpolatingParam[1]/@value) div number($projectWidth)) * 100)
				else
					c2jUtil:roundNumber(number(InterpolatingParam[1]/@value))
			" />
			<xsl:variable name="y" select="
				if (@name='translation') then
					c2jUtil:roundNumber(-(number(InterpolatingParam[2]/@value) div number($projectHeight)) * 100)
				else
					c2jUtil:roundNumber(number(InterpolatingParam[2]/@value))
			" />
			<xsl:variable name="z" select="c2jUtil:roundNumber(number(InterpolatingParam[3]/@value))" />

			<Transformation type="{@name}" x="{$x}" y="{$y}" z="{$z}" />
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
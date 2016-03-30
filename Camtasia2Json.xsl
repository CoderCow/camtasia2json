<?xml version="1.0" encoding="UTF-8" ?>

<!--
  Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
  Lizenz von Creative Commons zur Verfügung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/

  Autor: David Kay Posmyk <KayPosmyk@gmx.de>
-->

<!--
  Dies ist das primäre Stylesheet für die XSL Transformationen. Hier werden die eigentlichen JSON Ausgabedaten erzeugt.
  Dieses Stylesheet ist von folgenden weiteren Stylesheets abhängig:
    * Camtasia2Json.Config.xsl     Definiert allgemeine Konstanten für die Transformation und die Ausgabedatei.
    * Camtasia2Json.Utils.xsl      Definiert Hilfsmfunktionen für die XSL Verarbeitung.
    * Camtasia2Json.Resolvers.xsl  Selektiert die eigentlichen Daten aus der Camtasia Projektdatei und führt eine
                                   Vortransformation in, für die Auswertung besser geeignete, XML Strukturen durch.

  Hinweise zu den Namensräumen:
    * "c2jUtil" ist der Namensraum für in XSL selbstdefinierte Funktionen (da <xsl:functions immer in einem eigenen Namensraum
      sein müssen).
    * "xsltUtil" fungiert wie ein Java import und wird direkt auf die Java Klasse "XSLTUtil" gemappt.

  Achtung: Das Oracle XDK unterstützt nur ein älteres Working Draft der XSLT 2.0, XPATH 2.0 Spezifikationen, dadurch werden
  z.B. XSL Funktionen wie "matches" oder "lower-case" nicht unterstützt.
  Weitere Hinweise zur XSLT 2.0, XPath 2.0 Unterstützung: http://docs.oracle.com/cd/E28280_01/appdev.1111/b28394/adx_ref_standards.htm
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:c2jUtil="http://app.medien.hs-duesseldorf.de/camtasia2json/util"
	xmlns:xsltUtil="http://www.oracle.com/XSL/Transform/java/de.hs_duesseldorf.medien.app.camtasia2json.XSLTUtil"
>
	<xsl:output method="text" encoding="UTF-8" />
	<xsl:decimal-format name="en" decimal-separator="." grouping-separator="," />

	<xsl:include href="Camtasia2Json.Config.xsl" />
	<xsl:include href="Camtasia2Json.Utils.xsl" />
	<xsl:include href="Camtasia2Json.Resolvers.xsl" />

	<!-- Primäres Template -->
	<xsl:template match="/">
		<!-- Manchmal ist es nützlich XML Daten aus debug gründen direkt anzeigen zu lassen. Dafür das "method" Attribut im
		     <xsl:output> Element auf "xml" umstellen, damit bei der Ausgabe die XML Daten erhalten bleiben.
		     Achtung: Hierfür muss außerdem in der Java Hauptklasse der Debug-Modus aktiviert werden! -->
		<!-- <xsl:copy-of select="$transformedTracks" />-->

		{
			"id": <xsl:value-of select="$DEFAULT_ID" />,
			"meta": {
				<xsl:call-template name="metaBase" />

				"titles": [
					<xsl:call-template name="metaTitles" />
				],
				"descriptions": [
					<xsl:call-template name="metaDescriptions" />
				]
			},

			"media": {
				<xsl:call-template name="media" />
			},

			"categories": [
				<xsl:call-template name="categories" />
			],

			"chapters": [
				<xsl:call-template name="chapters" />
			],

			"authorNotes": [
				<xsl:call-template name="authorNotes" />
			],

			"captionSettings": {
				<xsl:call-template name="captionSettings" />
			},

			"captions": [
				<xsl:call-template name="captions" />
			],

			"overlaySettings": {
				<xsl:call-template name="overlaySettings" />
			},

			"overlays": [
				<xsl:call-template name="overlays" />
			]

			<xsl:if test="count($transformedAuthCamTracks/Media/Group) > 0">
				,
				"authCam": {
					<xsl:call-template name="authCam" />
				}
			</xsl:if>
		}
	</xsl:template>

	<xsl:template name="metaBase">
		<xsl:variable name="generalConfigCallout" select="$transformedConfigTrack/Media/Callout[ContentData/Attributes/Attribute[@name = 'Konfig Typ' and @value = 'Allgemein']]" />
		<xsl:variable name="generalConfigAttributes" select="$generalConfigCallout/ContentData/Attributes" />
		<xsl:if test="not($generalConfigCallout)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Entweder exestiert der Track "</xsl:text>
				<xsl:value-of select="$SPECIAL_TRACK_NAME_CONFIG" />
				<xsl:text>" nicht, oder auf ihm fehlt das erforderliche Callout für die allgemeine Konfiguration.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:variable name="socialConfigCallout" select="$transformedConfigTrack/Media/Callout[ContentData/Attributes/Attribute[@name = 'Konfig Typ' and @value = 'Social Sharing']]" />
		<xsl:variable name="socialConfigAttributes" select="$socialConfigCallout/ContentData/Attributes" />
		<xsl:if test="not($socialConfigCallout)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Entweder exestiert der Track "</xsl:text>
				<xsl:value-of select="$SPECIAL_TRACK_NAME_CONFIG" />
				<xsl:text>" nicht, oder auf ihm fehlt das erforderliche Callout für die Social Sharing Konfiguration.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:variable name="authorName" select="c2jUtil:validateRequiredAttribute($generalConfigAttributes/Attribute[@name = 'Autor']/@value, 'Autor', $generalConfigCallout, false)" /> <!-- TODO: später ggf. durch eine ID ersetzen. -->
		<xsl:variable name="posterUrl" select="c2jUtil:validateRequiredAttribute($generalConfigAttributes/Attribute[@name = 'Platzhalter URL']/@value, 'Platzhalter URL', $generalConfigCallout, true)" />
		<xsl:variable name="enableSocialShareButtons" select="c2jUtil:validateRequiredBooleanAttribute($socialConfigAttributes/Attribute[@name = 'Buttons Aktiv?']/@value, 'Buttons Aktiv?', $generalConfigCallout)" />
		<xsl:variable name="socialShareUrl" select="c2jUtil:validateRequiredAttribute($socialConfigAttributes/Attribute[@name = 'Share URL']/@value, 'Share URL', $generalConfigCallout, true)" />

		"version": "<xsl:value-of select="xsltUtil:jsonString($OUTPUT_FILE_VERSION)" />",
		"generator": "<xsl:value-of select="xsltUtil:jsonString($GENERATOR_INFO)" />",
		"cat": <xsl:value-of select="$metaCategory" />,
		"dur": <xsl:value-of select="c2jUtil:max($transformedTracks/Track/@dur)" />,
		"author": "<xsl:value-of select="xsltUtil:jsonString($authorName)" />",
		"date": "<xsl:value-of select="xsltUtil:jsonString($metaDate)" />",
		"defaultLang": "<xsl:value-of select="xsltUtil:jsonString($metaLanguage)" />",
		"contact": "", <!-- z.Z. nicht verwendet -->
		"enableSocialShareButtons": <xsl:value-of select="$enableSocialShareButtons" />,
		"socialShareUrl": "<xsl:value-of select="xsltUtil:jsonString($socialShareUrl)" />",
		"tags": "<xsl:value-of select="xsltUtil:jsonString($metaKeywords)" />",
		"poster": "<xsl:value-of select="xsltUtil:jsonString($posterUrl)" />",
	</xsl:template>

	<xsl:template name="metaTitles">
		{
			"lang": "<xsl:value-of select="xsltUtil:jsonString($metaLanguage)" />",
			"title": "<xsl:value-of select="xsltUtil:jsonString($metaTitle)" />"
		}
		<!-- Titel für alle anderen Sprachen. -->
		<xsl:for-each select="$transformedMetaTracks[@lang != $metaLanguage]">
			<xsl:variable name="lang" select="@lang" />
			<xsl:variable name="extraTitle" select="c2jUtil:getMetadataMediumAttributeValue(., 'Titel', 'Titel')" />

			, {
				"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
				"title": "<xsl:value-of select="xsltUtil:jsonString($extraTitle)" />"
			}
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="metaDescriptions">
		{
			"lang": "<xsl:value-of select="xsltUtil:jsonString($metaLanguage)" />",
			"description": "<xsl:value-of select="xsltUtil:jsonString($metaDescription)" />"
		}
		<!-- Beschreibung für alle anderen Sprachen. -->
		<xsl:for-each select="$transformedMetaTracks[@lang != $metaLanguage]">
			<xsl:variable name="lang" select="xsltUtil:jsonString(@lang)" />
			<xsl:variable name="extraDescription" select="c2jUtil:getMetadataMediumAttributeValue(., 'Beschreibung', 'Beschreibung')" />

			<xsl:if test="$extraDescription != ''">
				, {
					"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
					"description": "<xsl:value-of select="xsltUtil:jsonString($extraDescription)" />"
				}
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="media">
		"digital": [
			<xsl:variable name="defaultLangMedia" select="c2jUtil:getMetadataMediumAttributeValue($transformedMetaTracks[@lang = $metaLanguage], 'Medium', 'Mediendatei URL')" />

			<xsl:if test="local-name($defaultLangMedia) = ''">
				<xsl:message terminate="yes">
					<xsl:text>FEHLER: Der Track "</xsl:text>
					<xsl:value-of select="$SPECIAL_TRACK_NAME_METADATA" />
					<xsl:text>" exestiert entweder nicht, oder enthält keine Metadaten für mindestens eine Mediendatei.</xsl:text>
				</xsl:message>
			</xsl:if>

			<xsl:for-each select="$transformedMetaTracks/Media/Callout[ContentData/Attributes/Attribute[@name = 'Metadaten Typ' and @value = 'Medium']]">
				<xsl:variable name="medium" select="." />
				<xsl:variable name="lang" select="ancestor::Track/@lang" />
				<xsl:variable name="src" select="c2jUtil:validateRequiredAttribute($medium/ContentData/Attributes/Attribute[@name = 'Mediendatei URL']/@value, 'Mediendatei URL', $medium, false)" />
				<xsl:variable name="type" select="c2jUtil:validateRequiredAttribute($medium/ContentData/Attributes/Attribute[@name = 'MIME Typ']/@value, 'MIME Typ', $medium, false)" />

				{
					"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
					"type": "<xsl:value-of select="xsltUtil:jsonString($type)" />",
					"src": "<xsl:value-of select="xsltUtil:jsonString($src)" />"
				}
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		]
	</xsl:template>

	<xsl:template name="categories">
		<xsl:for-each select="$transformedCategoryTracks/Media/Callout">
			<xsl:variable name="lang" select="ancestor::Track/@lang" />
			<xsl:variable name="contentAttributes" select="ContentData/Attributes" />
			<xsl:variable name="title" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Titel']/@value, 'Titel', ., false)" />
			<xsl:variable name="tooltip" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Tooltip']/@value, 'Tooltip', ., true)" />
			<xsl:variable name="description" select="ContentData/Html/text()" />

			{
				"id": <xsl:value-of select="@id" />,
				"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
				"title": "<xsl:value-of select="xsltUtil:jsonString($title)" />",
				"begin": <xsl:value-of select="@begin" />,
				"dur": <xsl:value-of select="@dur" />,
				"description": "<xsl:value-of select="xsltUtil:jsonString($description)" />",
				"tooltip": "<xsl:value-of select="xsltUtil:jsonString($tooltip)" />"
			}
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="chapters">
		<xsl:for-each select="$transformedChapterTracks/Media/Callout">
			<xsl:variable name="lang" select="ancestor::Track/@lang" />
			<xsl:variable name="contentAttributes" select="ContentData/Attributes" />
			<xsl:variable name="title" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Titel']/@value, 'Titel', ., false)" />
			<xsl:variable name="tooltip" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Tooltip']/@value, 'Tooltip', ., true)" />
			<xsl:variable name="tags" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Tags']/@value, 'Tags', ., true)" />
			<xsl:variable name="description" select="ContentData/Html/text()" />
			<xsl:variable name="begin" select="@begin" />
			<xsl:variable name="end" select="@end" />
			<xsl:variable name="categoryId" select="$transformedCategoryTracks[@lang = $lang]/Media/Callout[number($begin) ge number(@begin) and number($end) le number(@end)]/@id" />

			<!-- Kategoriezuordnungen werden nur beachtet, wenn auch Kategorien exestieren. -->
			<xsl:variable name="considerCategories" select="count($transformedCategoryTracks[@lang = $lang]/Media/Callout) > 0" />

			<xsl:if test="$considerCategories and not($categoryId)">
				<xsl:message>
					<xsl:text>WARNUNG: Für das Kapitel </xsl:text>
					<xsl:value-of select="c2jUtil:identifyMediumForUser(.)" />
					<xsl:text> konnte anhand der Positionierung auf der Zeitleiste keine Kategorie zugeordnet werden.</xsl:text>
				</xsl:message>
			</xsl:if>

			{
				"id": <xsl:value-of select="@id" />,
				"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
				"title": "<xsl:value-of select="xsltUtil:jsonString($title)" />",
				"begin": <xsl:value-of select="@begin" />,
				"dur": <xsl:value-of select="@dur" />,
				"videoType": "<xsl:value-of select="xsltUtil:jsonString($CHAPTER_DEFAULT_VIDEO_TYPE)" />",
				"description": "<xsl:value-of select="xsltUtil:jsonString($description)" />",
				<xsl:if test="$categoryId">
					"category": <xsl:value-of select="$categoryId" />,
				</xsl:if>
				"tooltip": "<xsl:value-of select="xsltUtil:jsonString($tooltip)" />",
				"tags": "<xsl:value-of select="xsltUtil:jsonString($tags)" />",
				"charts": [],
				"additionals": [
					<xsl:variable name="chapterExtraMedia" select="$transformedChapterExtraTracks[@lang = $lang]/Media/*[number(@begin) ge number($begin) and number(@begin) le number($end)]" />
					<xsl:for-each select="$chapterExtraMedia">
						<xsl:variable name="type" select="@name" />

						<xsl:choose>
							<xsl:when test="$type = $SPECIAL_GROUP_NAME_LINKLIST">
								<xsl:call-template name="additionals_linkList">
									<xsl:with-param name="groupMedium" select="." />
								</xsl:call-template>
								<xsl:if test="position() != last()">,</xsl:if>
							</xsl:when>
							<xsl:otherwise>
								<xsl:message terminate="yes">
									FEHLER: Der Typ eines Extras <xsl:value-of select="c2jUtil:identifyMediumForUser(.)" /> konnte nicht ermittelt werden.".
								</xsl:message>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:if test="position() != last()">,</xsl:if>
					</xsl:for-each>
				]
			}
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="additionals_linkList">
		<xsl:param name="groupMedium" />

		<!-- Enumeriere alle Inhaltsdaten aller Medien der Gruppe. -->
		<xsl:variable name="listItemContentData">
			<xsl:for-each select="$groupMedium/SubMedia/*">
				<xsl:if test="local-name(.) != 'Callout'">
					<xsl:message>
						<xsl:text>WARNUNG: Eine Medium </xsl:text>
						<xsl:value-of select="c2jUtil:identifyMediumForUser(.)" />
						<xsl:text> ist kein Callout, obwohl in Linklisten nur solche unterstützt werden.</xsl:text>
					</xsl:message>
				</xsl:if>

				<xsl:variable name="isListHead" select="not(ContentData/Attributes/Attribute[@name = 'URL'])" />

				<Item isListHead="{$isListHead}">
					<xsl:copy-of select="./ContentData/*" />
				</Item>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="headContent" select="$listItemContentData/Item[@isListHead = 'true']" />
		<xsl:if test="not($headContent)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: In der Linkliste </xsl:text>
				<xsl:value-of select="c2jUtil:identifyMediumForUser($groupMedium)" />
				<xsl:text> befindet sich kein Listenkopf.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:variable name="headContentAttributes" select="$headContent/Attributes" />
		<xsl:variable name="title" select="c2jUtil:validateRequiredAttribute($headContentAttributes/Attribute[@name = 'Titel']/@value, 'Titel', ., false)" />
		<xsl:variable name="tooltip" select="c2jUtil:validateRequiredAttribute($headContentAttributes/Attribute[@name = 'Tooltip']/@value, 'Tooltip', ., true)" />
		<xsl:variable name="description" select="ContentData/Html/text()" />

		{
			"type": "linklist",
			"title": "<xsl:value-of select="xsltUtil:jsonString($title)" />",
			"description": "<xsl:value-of select="xsltUtil:jsonString($description)" />",
			"tooltip": "<xsl:value-of select="xsltUtil:jsonString($tooltip)" />",
			"links": [
				<xsl:variable name="linkMediaContent" select="$listItemContentData/Item[@isListHead = 'false']" />
				<xsl:if test="count($linkMediaContent) = 0">
					<xsl:message>
						<xsl:text>WARNUNG: In der Linkliste </xsl:text>
						<xsl:value-of select="c2jUtil:identifyMediumForUser($groupMedium)" />
						<xsl:text> befinden sich neben einem Listenkopf keine Links für die Liste.</xsl:text>
					</xsl:message>
				</xsl:if>

				<xsl:for-each select="$linkMediaContent">
					<xsl:call-template name="linkItem">
						<xsl:with-param name="contentData" select="." />
					</xsl:call-template>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			]
		}
	</xsl:template>

	<xsl:template name="linkItem">
		<xsl:param name="contentData" />
		<xsl:variable name="linkContentAttributes" select="$contentData/Attributes" />
		<xsl:variable name="linkTitle" select="c2jUtil:validateRequiredAttribute($linkContentAttributes/Attribute[@name = 'Titel']/@value, 'Titel', ., false)" />
		<xsl:variable name="linkHref" select="c2jUtil:validateRequiredAttribute($linkContentAttributes/Attribute[@name = 'URL']/@value, 'URL', ., false)" />
		<xsl:variable name="linkTooltip" select="c2jUtil:validateRequiredAttribute($linkContentAttributes/Attribute[@name = 'Tooltip']/@value, 'Tooltip', ., true)" />

		{
			"title": "<xsl:value-of select="xsltUtil:jsonString($linkTitle)" />",
			"href": "<xsl:value-of select="xsltUtil:jsonString($linkHref)" />",
			"tooltip": "<xsl:value-of select="xsltUtil:jsonString($linkTooltip)" />"
		}
	</xsl:template>

	<xsl:template name="authorNotes">
		<xsl:for-each select="$transformedNoteTracks/Media/Callout">
			<xsl:variable name="lang" select="ancestor::Track/@lang" />
			<xsl:variable name="contentAttributes" select="ContentData/Attributes" />
			<xsl:variable name="title" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Titel']/@value, 'Titel', ., false)" />
			<xsl:variable name="tooltip" select="$contentAttributes/Attribute[@name = '*Tooltip']/@value" />
			<xsl:variable name="takeDuration" select="c2jUtil:validateBooleanAttribute($contentAttributes/Attribute[@name = 'Länge übernehmen?']/@value, 'Länge übernehmen?', .)" />
			<xsl:variable name="displayInTimeline" select="c2jUtil:validateBooleanAttribute($contentAttributes/Attribute[@name = 'In Zeitleiste anzeigen?']/@value, 'In Zeitleiste anzeigen?', .)" />
			<xsl:variable name="displayInChapters" select="c2jUtil:validateBooleanAttribute($contentAttributes/Attribute[@name = 'In Kapiteln anzeigen?']/@value, 'In Kapiteln anzeigen?', .)" />
			<xsl:variable name="displayOnScreen" select="c2jUtil:validateBooleanAttribute($contentAttributes/Attribute[@name = 'Auf Bildschirm anzeigen?']/@value, 'Auf Bildschirm anzeigen?', .)" />
			<xsl:variable name="content" select="ContentData/Html/text()" />
			<xsl:variable name="begin" select="@begin" />
			<xsl:variable name="end" select="@end" />
			<xsl:variable name="chapterId" select="$transformedChapterTracks[@lang = $lang]/Media/Callout[number($begin) ge number(@begin) and number($end) le number(@end)]/@id" />
			<xsl:if test="not($chapterId)">
				<xsl:message>
					<xsl:text>WARNUNG: Für die Autorennotiz </xsl:text>
					<xsl:value-of select="c2jUtil:identifyMediumForUser(.)" />
					<xsl:text> konnte anhand der Positionierung auf der Zeitleiste kein Kapitel zugeordnet werden.</xsl:text>
				</xsl:message>
			</xsl:if>

			{
				"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
				"begin": <xsl:value-of select="@begin" />,
				<!-- Der Benutzer entscheidet, ob die Länge übernommen wird oder nicht. -->
				<xsl:if test="$takeDuration = 'true'">
					"dur": <xsl:value-of select="@dur" />,
				</xsl:if>
				"title": "<xsl:value-of select="xsltUtil:jsonString($title)" />",
				"tooltip": "<xsl:value-of select="xsltUtil:jsonString($tooltip)" />",
				"content": "<xsl:value-of select="xsltUtil:jsonString($content)" />",
				<xsl:if test="$chapterId">
					"chapter": <xsl:value-of select="$chapterId" />,
				</xsl:if>
				"displayInTimeline": <xsl:value-of select="$displayInTimeline" />,
				"displayInChapters": <xsl:value-of select="$displayInChapters" />,
				"displayOnScreen": <xsl:value-of select="$displayOnScreen" />
			}
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="captionSettings">
		<xsl:variable name="captionAttributes" select="//Timeline/CaptionAttributes" />
		<xsl:variable name="fontName" select="$captionAttributes/Attribute[@name = 'captionsFontName']/@value" />
		<xsl:variable name="backgroundColor" select="c2jUtil:camtasiaColorToJSONArray($captionAttributes/Attribute[@name = 'captionsBackgroundColor']/@value)" />
		<xsl:variable name="foregroundColor" select="c2jUtil:camtasiaColorToJSONArray($captionAttributes/Attribute[@name = 'captionsForegroundColor']/@value)" />
		<xsl:variable name="opacity" select="$captionAttributes/Attribute[@name = 'captionsOpacity']/@value" />
		<xsl:variable name="isBackgroundEnabled" select="$captionAttributes/Attribute[@name = 'captionsBackgroundEnabled']/@value = '1'" />
		<xsl:variable name="isBackgroundOnlyAroundText" select="$captionAttributes/Attribute[@name = 'captionsBackgroundOnlyAroundText']/@value = '1'" />
		<xsl:variable name="alignmentRaw" select="$captionAttributes/Attribute[@name = 'captionsAlignment']/@value" />
		<xsl:variable name="alignment" select="
			if ($alignmentRaw = '0' or $alignmentRaw = '2') then
				'center'
			else if ($alignmentRaw = '1') then
				'left'
			else
				'right'
		" />

		"fontName": "<xsl:value-of select="xsltUtil:jsonString($fontName)" />",
		"backgroundColor": <xsl:value-of select="$foregroundColor" />,
		"foregroundColor": <xsl:value-of select="$backgroundColor" />,
		"alignment": "<xsl:value-of select="$alignment" />",
		"opacity": <xsl:value-of select="$opacity" />,
		"isBackgroundEnabled": <xsl:value-of select="$isBackgroundEnabled" />,
		"isBackgroundOnlyAroundText": <xsl:value-of select="$isBackgroundOnlyAroundText" />
	</xsl:template>

	<xsl:template name="captions">
		<xsl:for-each select="$transformedSubtitleTracks/Media/Caption">
			<xsl:if test="position() gt 1">,</xsl:if>
			<xsl:variable name="lang" select="ancestor::Track/@lang" />
			<xsl:variable name="mediumBegin" select="@begin" />

			<xsl:for-each select="CaptionData/Caption">
				<xsl:variable name="begin" select="format-number(number($mediumBegin) + number(@relativeBegin), '#.##', 'en')" />
				<xsl:variable name="content" select="@html" />

				{
					"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
					"begin": <xsl:value-of select="$begin" />,
					"dur": <xsl:value-of select="@dur" />,
					"content": "<xsl:value-of select="xsltUtil:jsonString($content)" />"
				}
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="overlaySettings">
		<xsl:variable name="configMedium" select="$transformedConfigTrack/Media/Callout[ContentData/Attributes/Attribute[@name = 'Konfig Typ' and @value = 'Overlays']]" />
		<xsl:if test="not($configMedium)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Entweder exestiert der Track "</xsl:text>
				<xsl:value-of select="$SPECIAL_TRACK_NAME_CONFIG" />
				<xsl:text>" nicht, oder auf ihm fehlt das erforderliche Callout für die Overlay-Konfiguration.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:variable name="configAttributes" select="$configMedium/ContentData/Attributes" />
		<xsl:variable name="isEnabledByDefault" select="c2jUtil:validateRequiredBooleanAttribute($configAttributes/Attribute[@name = 'Standardmäßig Aktiv?']/@value, 'Standardmäßig Aktiv?', $configMedium)" />
		<xsl:variable name="isSwitchable" select="c2jUtil:validateRequiredBooleanAttribute($configAttributes/Attribute[@name = 'Ausschaltbar?']/@value, 'Ausschaltbar?', $configMedium)" />

		"isEnabledByDefault": <xsl:value-of select="$isEnabledByDefault" />,
    "isSwitchable": <xsl:value-of select="$isSwitchable" />
	</xsl:template>

	<xsl:template name="overlays">
		<xsl:for-each select="$transformedOverlayTracks/Media/*">
			<xsl:variable name="mediumType" select="local-name(.)" />
			<!-- Wenn es sich um ein Gruppenmedium handelt, dann haben wir wahrscheinlich eine Linkliste. Hier müssen wir dann das Metacallout
			     finden, also das Callout das selbst keinen Link der Linkliste repräsentiert. Und das lässt sich einfach dadurch bewerkstelligen,
			     dass wir nach einem beliebigen Pflichtattribut eines Overlays suchen. -->
			<xsl:variable name="metaMedium" select="
				if ($mediumType = 'Group') then
					SubMedia/Callout[ContentData/Attributes/Attribute[@name = 'Erzwinge Anzeige?']]
				else
					.
			" />
			<xsl:if test="not($metaMedium) and $mediumType = 'Group'">
				<xsl:message terminate="yes">
					<xsl:text>FEHLER: Die Gruppe </xsl:text>
					<xsl:value-of select="c2jUtil:identifyMediumForUser(.)" />
					<xsl:text> ist keine gültige Gruppe für ein Linklisten-Overlay, da das Callout mit den entsprechenden Metadaten fehlt.</xsl:text>
				</xsl:message>
			</xsl:if>

			<xsl:variable name="lang" select="ancestor::Track/@lang" />
			<xsl:variable name="contentAttributes" select="$metaMedium/ContentData/Attributes" />
			<xsl:variable name="content" select="$metaMedium/ContentData/Html/text()" />
			<xsl:variable name="style" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Stilklasse']/@value, 'Stilklasse', $metaMedium, false)" />
			<xsl:variable name="position" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Positionsklasse']/@value, 'Positionsklasse', $metaMedium, false)" />
			<xsl:variable name="isCopyable" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Kopierbarer Inhalt?']/@value, 'Kopierbarer Inhalt?', $metaMedium)" />
			<xsl:variable name="waitForAction" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Auf Aktion warten?']/@value, 'Auf Aktion warten?', $metaMedium)" />
			<xsl:variable name="closeOnAction" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Bei Aktion schließen?']/@value, 'Bei Aktion schließen?', $metaMedium)" />
			<xsl:variable name="closeButton" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Schließen Button?']/@value, 'Schließen Button?', $metaMedium)" />
			<xsl:variable name="forceVisibility" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Erzwinge Anzeige?']/@value, 'Erzwinge Anzeige?', $metaMedium)" />
			<xsl:variable name="closeAutomatically" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Automatisch schließen?']/@value, 'Automatisch schließen?', $metaMedium)" />
			<xsl:variable name="tooltip" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Tooltip']/@value, 'Tooltip', $metaMedium, true)" />

			<xsl:variable name="hotspotInfo" select="$metaMedium/HotspotInfo" />
			<xsl:variable name="actionId" select="$hotspotInfo/@action" />
			<xsl:variable name="actionTargetPos" select="c2jUtil:framesToSeconds($hotspotInfo/@gotoTime)" />
			<xsl:variable name="actionTargetMarkerPos" select="c2jUtil:framesToSeconds($hotspotInfo/@markerTime)" />
			<xsl:variable name="actionLinkUrl" select="$hotspotInfo/@url" />
			<xsl:variable name="actionLinkNewWindow" select="c2jUtil:validateBooleanAttribute($hotspotInfo/@openURLInNewWindow, 'Hotspot Daten: Link in neuem Browserfenster öffnen', $metaMedium)" />
			<xsl:variable name="pauseAtEnd" select="$hotspotInfo/@pauseAtEnd = 1" />

			{
				"id": <xsl:value-of select="@id" />,
				"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />",
				"begin": <xsl:value-of select="@begin" />,
				<xsl:if test="$closeAutomatically = 'true'">
					"dur": <xsl:value-of select="@dur" />,
				</xsl:if>
				"content": "<xsl:value-of select="xsltUtil:jsonString($content)" />",
				"isCopyableContent": <xsl:value-of select="$isCopyable" />,
        "style": "<xsl:value-of select="xsltUtil:jsonString($style)" />",
        "position": "<xsl:value-of select="xsltUtil:jsonString($position)" />",
					<xsl:choose>
						<xsl:when test="$mediumType = 'Group'">
							"action": "linklist",
							"actionParams": {
								"links": [
									<xsl:variable name="linkMedia" select="SubMedia/Callout[not(ContentData/Attributes/Attribute[@name = 'Erzwinge Anzeige?'])]" />
									<xsl:if test="not($linkMedia) or count($linkMedia) = 0">
										<xsl:message terminate="yes">
											<xsl:text>FEHLER: In der Gruppe für ein Linklisten-Overlay </xsl:text>
											<xsl:value-of select="c2jUtil:identifyMediumForUser(.)" />
											<xsl:text> sind keine Links enthalten.</xsl:text>
										</xsl:message>
									</xsl:if>

									<xsl:for-each select="$linkMedia">
										<xsl:call-template name="linkItem">
											<xsl:with-param name="contentData" select="ContentData" />
										</xsl:call-template>
										<xsl:if test="position() != last()">,</xsl:if>
									</xsl:for-each>
								]
							},
						</xsl:when>
						<xsl:when test="not($hotspotInfo)"> <!-- Kein Hotspot = keine Aktion -->
							"action": "none",
							"actionParams": {},
						</xsl:when>
						<xsl:when test="$actionId = 0"> <!-- continue on click -->
							"action": "continue",
							"actionParams": {},
						</xsl:when>
						<xsl:when test="$actionId = 1"> <!-- goto pos -->
							"action": "goto",
							"actionParams": {
								"gotoPos": <xsl:value-of select="$actionTargetPos" />
							},
						</xsl:when>
						<xsl:when test="$actionId = 2"> <!-- open website -->
							"action": "link",
							"actionParams": {
								"href": "<xsl:value-of select="xsltUtil:jsonString($actionLinkUrl)" />",
			          "inNewWindow": <xsl:value-of select="$actionLinkNewWindow" />
							},
						</xsl:when>
						<xsl:when test="$actionId = 3"> <!-- goto marker -->
							"action": "goto",
							"actionParams": {
								"gotoPos": <xsl:value-of select="$actionTargetMarkerPos" />
							},
						</xsl:when>
						<xsl:otherwise>
							<xsl:message terminate="yes">
								<xsl:text>FEHLER: Die Aktion des Overlays </xsl:text>
								<xsl:value-of select="." />
								<xsl:text> konnte nicht verarbeitet werden.</xsl:text>
							</xsl:message>
						</xsl:otherwise>
					</xsl:choose>
			  "pauseAtEnd": <xsl:value-of select="$pauseAtEnd" />,
        "waitForAction": <xsl:value-of select="$waitForAction" />,
        "closeOnAction": <xsl:value-of select="$closeOnAction" />,
        "closeButton": <xsl:value-of select="$closeButton" />,
        "forceVisibility": <xsl:value-of select="$forceVisibility" />,
				"translateTransform":
					<xsl:call-template name="transform">
						<xsl:with-param name="transformation" select="$metaMedium/Transformations/Transformation[@type = 'translation']" />
					</xsl:call-template>,
				"rotateTransform":
					<xsl:call-template name="transform">
						<xsl:with-param name="transformation" select="$metaMedium/Transformations/Transformation[@type = 'rotation']" />
					</xsl:call-template>,
				"shearTransform":
					<xsl:call-template name="transform">
						<xsl:with-param name="transformation" select="$metaMedium/Transformations/Transformation[@type = 'shear']" />
					</xsl:call-template>,
        "w": <xsl:value-of select="$metaMedium/@width" />,
        "h": <xsl:value-of select="$metaMedium/@height" />,
				"opacity": <xsl:value-of select="$metaMedium/@opacity" />,
				"fadeInDuration": <xsl:value-of select="$metaMedium/@leftOpacityFadeDur" />,
				"fadeOutDuration": <xsl:value-of select="$metaMedium/@rightOpacityFadeDur" />,
        "tooltip": "<xsl:value-of select="xsltUtil:jsonString($tooltip)" />"
			}
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="authCam">
		<xsl:variable name="camGroup" select="$transformedAuthCamTracks/Media/Group" />
		<xsl:if test="count($camGroup) > 1">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Der Track "</xsl:text>
				<xsl:value-of select="$SPECIAL_TRACK_NAME_AUTHCAM" />
				<xsl:text>" darf nicht mehr als ein Gruppenelement enthalten.</xsl:text>
			</xsl:message>
		</xsl:if>

		<!-- Um das Callout zu finden, dass die Autorenkamera repräsentieren soll suchen wir nach einem beliebigen Attribut das
		     nur in diesem vorkommt. -->
		<xsl:variable name="camCallout" select="$camGroup/SubMedia/Callout[ContentData/Attributes/Attribute[@name = 'Positionsklasse']]" />
		<xsl:if test="not($camCallout)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Die Gruppe </xsl:text>
				<xsl:value-of select="c2jUtil:identifyMediumForUser($camGroup)" />
				<xsl:text> enthält keinen Callout der die Autorenkamera repräsentiert.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:variable name="camMediaCallouts" select="$camGroup/SubMedia/Callout[not(ContentData/Attributes/Attribute[@name = 'Positionsklasse'])]" />
		<xsl:if test="count($camMediaCallouts) lt 1">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: Die Gruppe </xsl:text>
				<xsl:value-of select="c2jUtil:identifyMediumForUser($camGroup)" />
				<xsl:text> enthält keine Callouts die die Mediendateien für die Autorenkamera definieren.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:variable name="contentAttributes" select="$camCallout/ContentData/Attributes" />
		<xsl:variable name="isSwitchable" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Ausschaltbar?']/@value, 'Ausschaltbar?', $camCallout)" />
		<xsl:variable name="isMoveable" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Verschiebbar?']/@value, 'Verschiebbar?', $camCallout)" />
		<xsl:variable name="isResizable" select="c2jUtil:validateRequiredBooleanAttribute($contentAttributes/Attribute[@name = 'Skalierbar?']/@value, 'Skalierbar?', $camCallout)" />
		<xsl:variable name="position" select="c2jUtil:validateRequiredAttribute($contentAttributes/Attribute[@name = 'Positionsklasse']/@value, 'Positionsklasse', $camCallout, false)" />

		"begin": <xsl:value-of select="$camGroup/@begin" />,
		"dur": <xsl:value-of select="$camGroup/@dur" />,
    "isSwitchable": <xsl:value-of select="$isSwitchable" />,
		"isMoveable": <xsl:value-of select="$isMoveable" />,
		"isResizable": <xsl:value-of select="$isResizable" />,
		"position": "<xsl:value-of select="xsltUtil:jsonString($position)" />",
		"w": <xsl:value-of select="$camCallout/@width" />,
		"h": <xsl:value-of select="$camCallout/@height" />,
		"translateTransform":
			<xsl:call-template name="transform">
				<xsl:with-param name="transformation" select="$camCallout/Transformations/Transformation[@type = 'translation']" />
			</xsl:call-template>,
		"rotateTransform":
			<xsl:call-template name="transform">
				<xsl:with-param name="transformation" select="$camCallout/Transformations/Transformation[@type = 'rotation']" />
			</xsl:call-template>,
		"shearTransform":
			<xsl:call-template name="transform">
				<xsl:with-param name="transformation" select="$camCallout/Transformations/Transformation[@type = 'shear']" />
			</xsl:call-template>,
		"opacity": <xsl:value-of select="$camCallout/@opacity" />,
		"fadeInDuration": <xsl:value-of select="$camCallout/@leftOpacityFadeDur" />,
		"fadeOutDuration": <xsl:value-of select="$camCallout/@rightOpacityFadeDur" />,
		"media": [
			<xsl:for-each select="$camMediaCallouts/ContentData/Attributes">
				{
					<xsl:call-template name="mediaItem">
						<xsl:with-param name="mediaCalloutAttributes" select="." />
					</xsl:call-template>
				}
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		]
	</xsl:template>

	<xsl:template name="mediaItem">
		<xsl:param name="mediaCalloutAttributes" />

		<xsl:variable name="mediaFileUrl" select="c2jUtil:validateRequiredAttribute($mediaCalloutAttributes/Attribute[@name = 'Mediendatei URL']/@value, 'Mediendatei URL', $mediaCalloutAttributes, false)" />
		<xsl:variable name="mediaMimeType" select="c2jUtil:validateRequiredAttribute($mediaCalloutAttributes/Attribute[@name = 'MIME Typ']/@value, 'MIME Typ', $mediaCalloutAttributes, false)" />
		<xsl:variable name="lang" select="c2jUtil:validateRequiredAttribute($mediaCalloutAttributes/Attribute[@name = 'Sprache']/@value, 'Sprache', $mediaCalloutAttributes, false)" />

		"src": "<xsl:value-of select="xsltUtil:jsonString($mediaFileUrl)" />",
		"type": "<xsl:value-of select="xsltUtil:jsonString($mediaMimeType)" />",
		"lang": "<xsl:value-of select="xsltUtil:jsonString($lang)" />"
	</xsl:template>

	<xsl:template name="transform">
		<xsl:param name="transformation" />

		<xsl:text>[</xsl:text>
		<xsl:value-of select="$transformation/@x" />
		<xsl:text>, </xsl:text>
		<xsl:value-of select="$transformation/@y" />
		<xsl:text>, </xsl:text>
		<xsl:value-of select="$transformation/@z" />
		<xsl:text>]</xsl:text>
	</xsl:template>
</xsl:stylesheet>
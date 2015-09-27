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
	<!-- Diese Funktion verhält sich exakt wie substring-before, außer dass sie den gesamten String zurück gibt, wenn searchString
	     nicht enthalten ist. -->
	<xsl:function name="c2jUtil:substring-before">
		<xsl:param name="baseString" />
		<xsl:param name="searchString" />
		<xsl:variable name="substringBefore" select="substring-before($baseString, $searchString)" />

		<xsl:value-of select="
			if (string-length($substringBefore) > 0) then
				$substringBefore
			else
				$baseString
		" />
	</xsl:function>

	<!-- Diese Funktion verhält sich exakt wie substring-after, außer dass sie den gesamten String zurück gibt, wenn searchString
	     nicht enthalten ist. -->
	<xsl:function name="c2jUtil:substring-after">
		<xsl:param name="baseString" as="xsd:string" />
		<xsl:param name="searchString" as="xsd:string" />
		<xsl:variable name="substringAfter" select="substring-after($baseString, $searchString)" />

		<xsl:value-of select="
			if (string-length($substringAfter) > 0) then
				$substringAfter
			else
				$baseString
		" />
	</xsl:function>

	<!-- Normalisiert Framewerte. Ein Eingabewert von 123 oder 123/1 ergibt 123, 64/2 wird zu 32 usw. -->
	<xsl:function name="c2jUtil:normalizedFrames" as="xsd:double">
		<xsl:param name="frames" as="xsd:string" />

		<xsl:variable name="dividend" select="substring-before($frames, '/')" />
		<xsl:variable name="divisor" select="substring-after($frames, '/')" />

		<xsl:value-of select="
		  if ($dividend != '') then
		    format-number(number($dividend) div number($divisor), '#.##', 'en')
		  else
		    format-number(number($frames), '#.##', 'en')
		" />
	</xsl:function>

	<!-- Normalisiert einen Framewert und errechnet die Anzahl von Sekunden, ausgehend von CAMTASIA_FRAMERATE. -->
	<xsl:function name="c2jUtil:framesToSeconds" as="xsd:string">
		<xsl:param name="frames" as="xsd:string" />

		<xsl:value-of select="format-number(c2jUtil:normalizedFrames($frames) div number($CAMTASIA_FRAMERATE), '#.##', 'en')" />
	</xsl:function>

	<!-- Runded ein Nummer auf zwei Dezimalstellen. -->
	<xsl:function name="c2jUtil:roundNumber" as="xsd:float">
		<xsl:param name="input" />

		<xsl:value-of select="
			if (contains($input, 'e')) then
				format-number(number(substring-before($input, 'e')), '#.##', 'en')
			else
				format-number(number($input), '#.##', 'en')
		" />
	</xsl:function>

	<!-- Wandelt einen Camtasia Farbwert im Format (R,G,B,A) in ein JSON Array in Form von [R,G,B,A] um. -->
	<xsl:function name="c2jUtil:camtasiaColorToJSONArray">
		<xsl:param name="camtasiaColor" />
		<xsl:value-of select="xsltUtil:replace(xsltUtil:replace($camtasiaColor, '\(', '['), '\)', ']')" />
	</xsl:function>

	<xsl:function name="c2jUtil:validateLangCode">
		<xsl:param name="langCode" />

		<xsl:value-of select="xsltUtil:matches($langCode, '^\w{2}(-\w{2})?$')" />
	</xsl:function>

	<!-- Extrahiert den Dateinamen aus einem Dateipfad. z.B. C:\MyDir\MyFile.txt => MyFile.txt -->
	<xsl:function name="c2jUtil:pathFileName" as="xsd:string">
		<xsl:param name="path" as="xsd:string" />

		<xsl:value-of select="xsltUtil:replace($path, '[^\\/]*[\\/]', '')" />
	</xsl:function>

	<!-- Ermittelt das mathematische Maximum aus der gegebenen Liste von Zahlen und gibt es als Zahl mit max. 4 Dezimalstellen zurück. -->
	<xsl:function name="c2jUtil:max" as="xsd:double">
		<xsl:param name="values" />

		<xsl:variable name="endValueNodes">
			<xsl:for-each select="$values">
				<EndValue><xsl:value-of select="." /></EndValue>
			</xsl:for-each>
		</xsl:variable>

		<xsl:value-of select="format-number(number(xsltUtil:max($endValueNodes)), '#.####', 'en')" />
	</xsl:function>

	<!-- Gibt einen Text zurück, der ein Medium so für den Benutzer identifiziert, dass er in der Lage ist dieses in Camtasia Studio zu finden. -->
	<xsl:function name="c2jUtil:identifyMediumForUser">
		<xsl:param name="medium" />
		<xsl:variable name="isInGroup" select="$medium/ancestor::Group" />
		<!-- Es ist möglich, dass sich das gegebene Medium innerhalb einer Gruppe befindet.
		     Ist dies der Fall, dann sollte eher die Position und Track der Gruppe beschrieben werden statt die des Mediums. -->
		<xsl:variable name="mediumToIdentify" select="
			if ($isInGroup) then
				$medium/ancestor::Group[not(ancestor::Group)]
			else
				$medium
		" />

		<xsl:if test="$isInGroup">
			<xsl:variable name="groupName" select="$mediumToIdentify/@name" />

			<xsl:choose>
				<xsl:when test="string-length($groupName) gt 0">
					<xsl:text>in der Gruppe "</xsl:text>
					<xsl:value-of select="$groupName" />
					<xsl:text>" </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>in der unbenannten Gruppe </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>

		<xsl:variable name="position" select="$mediumToIdentify/@begin" />
		<xsl:variable name="trackName" select="$mediumToIdentify/ancestor::Track/@ident" />

		<xsl:text>bei Position </xsl:text>
		<xsl:value-of select="$position" />
		<xsl:text> Sek. auf Track "</xsl:text>
		<xsl:value-of select="$trackName" />
		<xsl:text>"</xsl:text>
	</xsl:function>

	<!-- Prüft ob ein erforderliches Attribut auch tatsächlich einen Wert hat und gibt einen entsprechenden Fehler aus,
	     falls dies nicht der Fall ist. Hat das Attribut einen Wert, so wird dieser zurückgegeben. -->
	<xsl:function name="c2jUtil:validateRequiredAttribute">
		<xsl:param name="attributeValue" />
		<xsl:param name="attributeName" as="xsd:string" />
		<xsl:param name="medium" as="xsd:element" />
		<xsl:param name="allowEmptyValue" as="xsd:boolean" />

		<xsl:if test="not($attributeValue)">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: In einem Medium </xsl:text>
				<xsl:value-of select="c2jUtil:identifyMediumForUser($medium)" />
				<xsl:text> ist das erforderliche Attribut "</xsl:text>
				<xsl:value-of select="$attributeName" />
				<xsl:text>" nicht vorhanden.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:if test="$allowEmptyValue = 'false' and string-length($attributeValue) = 0">
			<xsl:message terminate="yes">
				<xsl:text>FEHLER: In einem Medium </xsl:text>
				<xsl:value-of select="c2jUtil:identifyMediumForUser($medium)" />
				<xsl:text> hat das erforderliche Attribut "</xsl:text>
				<xsl:value-of select="$attributeName" />
				<xsl:text>" keinen Wert.</xsl:text>
			</xsl:message>
		</xsl:if>

		<xsl:value-of select="$attributeValue" />
	</xsl:function>

	<!-- Prüft ob ein Attribut entweder keinen oder einen numerischer Wert hat und gibt einen entsprechenden Fehler aus,
	     falls dies nicht der Fall ist. Der Wert des Attributs wird daraufhin als Nummer zurückgegeben. -->
	<xsl:function name="c2jUtil:validateNumberAttribute" as="xsd:float">
		<xsl:param name="attributeValue" />
		<xsl:param name="attributeName" as="xsd:string" />
		<xsl:param name="medium" as="xsd:element" />

		<xsl:choose>
			<xsl:when test="string-length($attributeValue) gt 0">
				<xsl:if test="not($attributeValue castable as xsd:double)">
					<xsl:variable name="trackName" select="ancestor::Track/@ident" />

					<xsl:message terminate="yes">
						<xsl:text>FEHLER: In einem Medium </xsl:text>
						<xsl:value-of select="c2jUtil:identifyMediumForUser($medium)" />
						<xsl:text> hat das Attribut "</xsl:text>
						<xsl:value-of select="$attributeName" />
						<xsl:text>" keinen gültigen numerischen Wert.</xsl:text>
					</xsl:message>
				</xsl:if>

				<xsl:value-of select="format-number(number($attributeValue), '#.######', 'en')" />
			</xsl:when>
			<xsl:otherwise>
				''
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Prüft ob ein erforderliches Attribut auch tatsächlich einen numerischen Wert hat und gibt einen entsprechenden Fehler aus,
	     falls dies nicht der Fall ist. Der Wert des Attributs wird daraufhin als Nummer zurückgegeben. -->
	<xsl:function name="c2jUtil:validateRequiredNumberAttribute" as="xsd:float">
		<xsl:param name="attributeValue" />
		<xsl:param name="attributeName" as="xsd:string" />
		<xsl:param name="medium" as="xsd:element" />

		<xsl:value-of select="c2jUtil:validateNumberAttribute(c2jUtil:validateRequiredAttribute($attributeValue, $attributeName, $medium, true), $attributeName, $medium)" />
	</xsl:function>

	<!-- Prüft ob ein Attribut entweder keinen oder einen booleschen Wert hat und gibt einen entsprechenden Fehler aus,
	     falls dies nicht der Fall ist. Der Wert des Attributs wird daraufhin als Boolean zurückgegeben. -->
	<xsl:function name="c2jUtil:validateBooleanAttribute" as="xsd:boolean">
		<xsl:param name="attributeValue" />
		<xsl:param name="attributeName" as="xsd:string" />
		<xsl:param name="medium" as="xsd:element" />

		<xsl:choose>
			<xsl:when test="string-length($attributeValue) gt 0">
				<xsl:variable name="attributeValueLC" select="xsltUtil:lowerCase($attributeValue)" />
				<xsl:variable name="isTrueValue" select="
					$attributeValueLC = 'yes' or $attributeValueLC = 'ja' or $attributeValueLC = 'true' or $attributeValueLC = 'wahr' or $attributeValueLC = '1'
				" />
				<xsl:variable name="isFalseValue" select="
					$attributeValueLC = 'no' or $attributeValueLC = 'nein' or $attributeValueLC = 'false' or $attributeValueLC = 'wahr' or $attributeValueLC = '0'
				" />

				<xsl:if test="not($isTrueValue) and not($isFalseValue)">
					<xsl:variable name="trackName" select="ancestor::Track/@ident" />

					<xsl:message terminate="yes">
						<xsl:text>FEHLER: In einem Medium </xsl:text>
						<xsl:value-of select="c2jUtil:identifyMediumForUser($medium)" />
						<xsl:text> hat das Attribut "</xsl:text>
						<xsl:value-of select="$attributeName" />
						<xsl:text>" keinen gültigen booleschen Wert.</xsl:text>
					</xsl:message>
				</xsl:if>

				<xsl:value-of select="$isTrueValue" />
			</xsl:when>
			<xsl:otherwise>
				''
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Prüft ob ein erforderliches Attribut auch tatsächlich einen booleschen Wert hat und gibt einen entsprechenden Fehler aus,
	     falls dies nicht der Fall ist. Der Wert des Attributs wird daraufhin als Nummer zurückgegeben. -->
	<xsl:function name="c2jUtil:validateRequiredBooleanAttribute" as="xsd:boolean">
		<xsl:param name="attributeValue" />
		<xsl:param name="attributeName" as="xsd:string" />
		<xsl:param name="medium" as="xsd:element" />

		<xsl:value-of select="c2jUtil:validateBooleanAttribute(c2jUtil:validateRequiredAttribute($attributeValue, $attributeName, $medium, true), $attributeName, $medium)" />
	</xsl:function>
</xsl:stylesheet>
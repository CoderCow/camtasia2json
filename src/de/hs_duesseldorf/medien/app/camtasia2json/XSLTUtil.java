/**
 * Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
 * Lizenz von Creative Commons zur Verf�gung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/
 *
 * @author David Kay Posmyk <KayPosmyk@gmx.de>
 */

package de.hs_duesseldorf.medien.app.camtasia2json;

import com.sun.istack.internal.NotNull;
import oracle.xml.parser.v2.NodeFactory;
import oracle.xml.parser.v2.XMLDocumentFragment;
import oracle.xml.parser.v2.XMLElement;

import javax.swing.*;
import javax.swing.text.BadLocationException;
import javax.swing.text.EditorKit;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.regex.Pattern;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.safety.Whitelist;
import org.jsoup.select.Elements;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Stellt Erweiterungsmethoden f�r die XSL Transformation bereit. Die Methoden innerhalb dieser Klasse k�nnen direkt aus den XSL
 * dokumenten heraus aufgerufen werden.
 */
@SuppressWarnings("unused")
public class XSLTUtil {
	private static DateFormat englishDateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH);

	/**
	 * Gibt das heutige Datum zur�ck.
	 * @return Das heutige Datum im Format "yyyy-MM-dd".
	 */
	public static String dateNow() {
		return XSLTUtil.englishDateFormat.format(new Date());
	}

	/**
	 * Konvertiert eine Datumsangabe von einem Format in ein anderes.
	 * @param inputDate Das Eingabedatum das dem Format in inputFormatPattern entspricht.
	 * @return Datum das dem Format in outputFormatPattern entspricht.
	 * @throws ParseException Das Eingabedatum passt nicht zum im inputFormatPattern angegebene Format.
	 */
	public static String convertDate(
		@NotNull String inputDate, @NotNull String inputFormatPattern, @NotNull String outputFormatPattern) throws ParseException
	{
		if (inputDate == null)
			throw new IllegalArgumentException("inputDate can not be null.");
		if (inputFormatPattern == null)
			throw new IllegalArgumentException("inputFormatPattern can not be null.");
		if (outputFormatPattern == null)
			throw new IllegalArgumentException("outputFormatPattern can not be null.");

		SimpleDateFormat inputFormat = new SimpleDateFormat(inputFormatPattern);
		SimpleDateFormat outputFormat = new SimpleDateFormat(outputFormatPattern);

		try {
			Date date = inputFormat.parse(inputDate);
			return outputFormat.format(date);
		} catch (ParseException ex) {
			// If the parsing fails, the date might be already in the correct format.
			try {
				Date date = outputFormat.parse(inputDate);
				return outputFormat.format(date);
			} catch (ParseException ex2) {
				throw ex;
			}
		}
	}

	/**
	 * Gibt die Eingabezeichenfolge in Kleinbuchstaben zur�ck.
	 * @param input Die Eingabezeichenfolge.
	 * @return Die Eingabezeichenfolge in Kleinbuchstaben.
	 */
	public static String lowerCase(@NotNull String input) {
		if (input == null)
			throw new IllegalArgumentException("input can not be null.");

		return input.toLowerCase();
	}

	/**
	 * Ermittelt das mathematische Maximum anhand der Textinhalte der Kindknoten im gegebenen XML Fragment.
	 * @param fragment Das XML Fragment das die Kindknoten mit den Eingabewerten enth�lt.
	 * @return Das mathematische Maximum.
	 * @throws ParseException Mindestens ein Kindknoten enth�lt einen Inhalt der nicht in eine Zahl konvertiert werden kann.
	 */
	public static double max(@NotNull XMLDocumentFragment fragment) throws ParseException {
		if (fragment == null)
			throw new IllegalArgumentException("fragment can not be null.");

		NodeList children = fragment.getChildNodes();
		double maxValue = 0;

		for (int i = 0; i < children.getLength(); i++) {
			Node node = children.item(i);

			double value = Double.parseDouble(node.getTextContent());
			if (!Double.isNaN(value) && !Double.isInfinite(value))
				maxValue = Math.max(value, maxValue);
		}

		return maxValue;
	}

	/**
	 * Pr�ft, ob der gegebene Regul�re Ausdruck auf die Eingabezeichenfolge passt.
	 * @param input Die Eingabezeichenfolge die gepr�ft werden soll.
	 * @param pattern Der Regul�re Ausdruck gegen den die Zeichenfolge gepr�ft werden soll.
	 * @return true, wenn die Eingabezeichenfolge auf den Regul�ren Ausdurck passt, sonst false.
	 */
	public static boolean matches(@NotNull String input, @NotNull String pattern) {
		if (input == null)
			throw new IllegalArgumentException("input can not be null.");
		if (pattern == null)
			throw new IllegalArgumentException("pattern can not be null.");

		Pattern compiledPattern = Pattern.compile(pattern);
		return compiledPattern.matcher(input).matches();
	}

	/**
	 * Ersetzt die Teile der Eingabezeichenfolge gegen die angegebene Zeichenfolge, die zum gegebenen Regul�ren Ausdruck passen.
	 * @param input Die Eingabezeichenfolge.
	 * @param searchPattern Der Regul�re Ausdruck zum bestimmen der zu ersetzenden Teile.
	 * @param replacement Die Zeichenfolge mit der die gefundenen Teile ersetzt werden sollen.
	 * @return Die Eingabezeichenfolge mit den entsprechend ersetzten Teilfolgen.
	 */
	public static String replace(@NotNull String input, @NotNull String searchPattern, @NotNull String replacement) {
		if (input == null)
			throw new IllegalArgumentException("input can not be null.");
		if (searchPattern == null)
			throw new IllegalArgumentException("searchPattern can not be null.");
		if (replacement == null)
			throw new IllegalArgumentException("replacement can not be null.");

		return input.replaceAll(searchPattern, replacement);
	}

	/**
	 * Zerlegt den Rich Text Format Inhalt eines Camtasia Studio Callouts in zwei Teile:
	 *  * Den Formatierbaren Inhalt umgewandelt in ein HTML Fragment.
	 *  * Die Liste der Attribute in Form von name / wert Paaren.
	 * Die Daten werden dabei in einem XML Fragment mit folgender Struktur zur�ckgegeben:
	 * <Html>
	 *   Formatierbarer Inhalt als HTML Fragment.
	 * </Html>
	 * <Attributes>
	 *   <Attribute Name="Attributname" Value="Attributwert" />
	 *   ...
	 * </Attributes>
	 * Das "Html" Element ist inhaltslos, falls in der Eingabezeichenfolge kein formatierbarer Inhalt enthalten war.
	 * Das "Attributes" Element hat keine Unterelemente, wenn keine Attribute exestieren bzw. wenn das Trennzeichen nicht
	 * vorhanden ist.
	 * @param inputRtfText Der Inhalt eines Callouts im Rich Text Format.
	 * @param textAttributesSeparatorLine Die Zeile die den formatierbaren Text und die Attributliste trennt.
	 * @return Das XML Fragment welches HTML und Attributliste enth�lt
	 * @throws IOException Des RTF Text ist entweder ung�ltig oder konnte nicht erfoglreich ins HTML Format �berf�hrt werden.
	 */
	public static XMLDocumentFragment camtasiaCalloutContentDataFromRtf(
		@NotNull String inputRtfText, @NotNull String textAttributesSeparatorLine) throws IOException
	{
		if (inputRtfText == null)
			throw new IllegalArgumentException("inputRtfText can not be null.");
		if (textAttributesSeparatorLine == null)
			throw new IllegalArgumentException("textAttributesSeparatorLine can not be null.");
		if (inputRtfText.trim().length() == 0)
			throw new IllegalArgumentException("rtfText can not be an empty string.");

		NodeFactory nodeFactory = new NodeFactory();
		XMLDocumentFragment resultSet = new XMLDocumentFragment();
		Element htmlBodyElement = XSLTUtil.rtfToHtmlBodyTag(inputRtfText);
		StringBuilder htmlContentBuilder = new StringBuilder();
		XMLElement htmlContent = nodeFactory.createElement("Html");
		XMLElement attributesContent = nodeFactory.createElement("Attributes");

		// Erstmal muss jetzt der Paragraph gefunden werden in dem die Attribute der Zweckentfremdung beginnen.
		boolean isHtmlContent = true; // So lange true bis MEDIA_ATTRIBUTE_SEPARATOR gefunden wurde.
		for (Element paragraph : htmlBodyElement.children()) {
			assert(paragraph.nodeName().equalsIgnoreCase("p"));
			assert(!paragraph.children().isEmpty());

			Element firstSpan = paragraph.child(0);
			assert(firstSpan.nodeName().equalsIgnoreCase("span"));

			boolean hasOneSpanOnly = (paragraph.children().last() == firstSpan);
			// Wir m�chten keine leeren Paragraphen, d.h. <p> Tags die nur einen einzigen leeren <span> enthalten.
			if (firstSpan.text().length() > 0 || !hasOneSpanOnly) {
				boolean isSeparator = (firstSpan.text().trim().equals(textAttributesSeparatorLine));
				isHtmlContent = (isHtmlContent && !isSeparator);

				if (isHtmlContent) {
					htmlContentBuilder.append(paragraph.outerHtml().replace("> ", ">").replace(" <", "<"));
					htmlContentBuilder.append(System.getProperty("line.separator"));
				} else if (!isSeparator) { // Ist ein Attribut?
					String attributeRaw = firstSpan.text();
					int attributeSeparatorIndex = attributeRaw.indexOf(':');
					String attributeName = attributeRaw.substring(0, attributeSeparatorIndex).trim();
					String attributeValue = attributeRaw.substring(attributeSeparatorIndex + 1).trim();

					XMLElement attributeElement = nodeFactory.createElement("Attribute");
					attributeElement.setAttribute("name", attributeName);
					attributeElement.setAttribute("value", attributeValue);
					attributesContent.appendChild(attributeElement);
				}
			}
		}
		htmlContent.setTextContent(htmlContentBuilder.toString());

		resultSet.appendChild(htmlContent);
		resultSet.appendChild(attributesContent);

		return resultSet;
	}

	/**
	 * Wandelt die RTF-Eingabezeichenfolge in ein HTML equivalente Zeichenfolge um.
	 * Das HTML Markup ist immer so aufgebaut, dass jede Zeile der Eingabezeichenfolge in einem eigenen <p> Tag
	 * vorliegt. Der eigentliche Text liegt in einem <span> Tag vor, wobei f�r jede Schrift�nderung weitere <span> Tags
	 * erzeugt werden. F�r Formatierungen wie "Fett" or "Kursiv" werden die veralteten <b> und <i> Tags eingef�gt.
	 * @param inputRtfText Die Eingabezeichenfolge im Rich Text Format.
	 * @param includeParasAndSpans Legt fest, ob das HTML auch <p> und <span> Tags beinhalten soll.
	 * @return Die Eingabezeichenfolge im HTML Format.
	 * @throws IOException Des RTF Text ist entweder ung�ltig oder konnte nicht erfoglreich ins HTML Format �berf�hrt werden.
	 */
	public static String rtfToHtml(@NotNull String inputRtfText, boolean includeParasAndSpans) throws IOException {
		if (inputRtfText == null)
			throw new IllegalArgumentException("inputRtfText can not be null.");

		Element bodyElement = XSLTUtil.rtfToHtmlBodyTag(inputRtfText);

		if (!includeParasAndSpans) {
			StringBuilder spanContents = new StringBuilder();
			for (Element paragraph : bodyElement.children()) {
				assert(paragraph.nodeName().equalsIgnoreCase("p"));
				assert(!paragraph.children().isEmpty());

				for (Element span : paragraph.children()) {
					assert(span.nodeName().equalsIgnoreCase("span"));

					spanContents.append(span.html());
				}
			}

			return spanContents.toString();
		} else {
			return bodyElement.html();
		}
	}

	/**
	 * Wandelt die RTF-Eingabezeichenfolge in HTML Dokument um und gibt dessen <body> Tag zur�ck.
	 * @param inputRtfText Die Eingabezeichenfolge im Rich Text Format.
	 * @return Das <body> Tag des resultierenden HTML Dokuments.
	 * @throws IOException Des RTF Text ist entweder ung�ltig oder konnte nicht erfoglreich ins HTML Format �berf�hrt werden.
	 */
	public static Element rtfToHtmlBodyTag(@NotNull String inputRtfText) throws IOException {
		if (inputRtfText == null)
			throw new IllegalArgumentException("inputRtfText can not be null.");

		StringReader reader = new StringReader(inputRtfText);
    JEditorPane editorPane = new JEditorPane();

    editorPane.setContentType("text/rtf");
    EditorKit kitRtf = editorPane.getEditorKitForContentType("text/rtf");

		javax.swing.text.Document editorDocument = editorPane.getDocument();
		try {
			kitRtf.read(reader, editorDocument, 0);
			EditorKit kitHtml = editorPane.getEditorKitForContentType("text/html");

			Writer htmlWriter = new StringWriter();
			kitHtml.write(htmlWriter, editorDocument, 0, editorDocument.getLength());
			String htmlDocumentRaw = htmlWriter.toString();
			Document htmlDocument = Jsoup.parse(htmlDocumentRaw);

			return htmlDocument.body();
		} catch (BadLocationException ex) { // Diese Exception sollte niemals auftreten.
			ex.printStackTrace();
			return null;
		}
	}

	/**
	 * Wandelt die Eingabezeichenfolge in einen JSON kompatibles string Literal um.
	 * @param input Die Eingabezeichenfolge.
	 * @return Die Eingabezeichenfolge als JSON kompatibles string Literal ohne Anf�hrungszeichen.
	 */
	public static String jsonString(@NotNull String input) {
		StringBuilder builder = new StringBuilder();

    for (int i = 0; i < input.length(); ++i) {
      char c = input.charAt(i);
      if (c >= 32 && c != 34 && c != 92) {
        builder.append(c);
      } else {
        switch(c) {
        case '\b':
          builder.append('\\');
          builder.append('b');
          break;
        case '\t':
          builder.append('\\');
          builder.append('t');
          break;
        case '\n':
          builder.append('\\');
          builder.append('n');
          break;
        case '\f':
          builder.append('\\');
          builder.append('f');
          break;
        case '\r':
          builder.append('\\');
          builder.append('r');
          break;
        case '\"':
        case '\\':
          builder.append('\\');
          builder.append(c);
          break;
        default:
          String hex = "000" + Integer.toHexString(c);
          builder.append("\\u").append(hex.substring(hex.length() - 4));
        }
      }
    }

    return builder.toString();
	}

	/**
	 * Gibt Versionsinformationen zur Anwendung zur�ck.
	 * @return Die Versionsinformationen.
	 */
	public static String versionInfo() {
		return Main.APP_VERSION;
	}
}

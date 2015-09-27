/**
 * Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
 * Lizenz von Creative Commons zur Verfügung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/
 *
 * @author David Kay Posmyk <KayPosmyk@gmx.de>
 */

package de.hs_duesseldorf.medien.app.camtasia2json;

import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.sun.istack.internal.NotNull;
import oracle.xml.parser.v2.DOMParser;
import oracle.xml.parser.v2.XMLDocument;
import oracle.xml.parser.v2.XMLParseException;
import oracle.xml.parser.v2.XSLException;
import org.xml.sax.SAXException;

/**
 * Hauptklasse der Anwendung.
 */
class Main {
	/**
	 * Aktiviert / Deaktiviert den Debug-Modus. Beim kompillieren einer Anwendung für den produktiven Einsatz immer auf
	 * false setzen!
	 * Im Debug-Modus wird das Ergebnis der Transformation direkt auf die Konsole ausgegeben. Es wird außerdem nicht durch
	 * einen JSON Parser geprüft oder reformatiert.
	 */
	private static final boolean DEBUG = false;

	public static final String APP_VERSION = "v1.0 (2015-09-21)";
	private static final String DEFAULT_XSL_FILENAME = "Camtasia2Json.xsl";

	/**
	 * Die Hauptmethode der Anwendung. Verarbeitet ein bis zwei Eingabeparameter: den Pfad zur Camtasia Studio Projektdatei,
	 * optional den Pfad für die Ausgabedatei und optional den Pfad zum XSL Stylesheet.
	 * Die Eingabedateien werden eingelesen, geprüft und eine Transformation der Projektdatei in eine JSON Datei vorgenommen.
	 * @param args Die Eingabeparameter beim Anwendungsaufruf.
	 */
	public static void main(String[] args) {
		try {
			if (args.length < 1 || args.length > 3 || args[0].equals("/?")) {
				Main.printHelpText();
				return;
			}

			URL projectFileUrl = Main.fixedFileUrl(args[0]);

			String destFileName = null;
			if (args.length > 1)
				destFileName = args[1];
			boolean outputToFile = (destFileName != null);

			if (outputToFile)
				destFileName = Main.properCheckedDestFileName(destFileName);

			String xslFileUrlString = Main.DEFAULT_XSL_FILENAME;
			if (args.length > 2)
				xslFileUrlString = args[2];
			URL xslFileUrl = Main.fixedFileUrl(xslFileUrlString);

			XMLDocument camtasiaDocument = Main.xmlDocumentFromFile(projectFileUrl);
			XMLDocument xslDocument = Main.xmlDocumentFromFile(xslFileUrl);
			boolean bothFilesValid = (camtasiaDocument != null && xslDocument != null);
			if (bothFilesValid) {
				Camtasia2JsonProcessor processor;
				try {
					processor = new Camtasia2JsonProcessor(xslDocument, xslFileUrl);
				} catch (XSLException ex) {
					throw new Camtasia2JsonException(String.format("Das XSL Stylesheet \"%s\" ist fehlerhaft: %s\n", xslFileUrl, ex.getMessage()), ex);
				}

				try {
					processor.readCamtasiaProject(camtasiaDocument);
				} catch (XSLException ex) {
					// Keine zusätzliche Fehlermeldung ausgeben, wenn der Fehler von einer <xsl:message> ausgelöst wurde.
					if (!ex.getXMLError().getMessage(0).equals("TERMINATE PROCESSING"))
						throw new Camtasia2JsonException(String.format("Die XSL Transformation für die Datei \"%s\" ist fehlgeschlagen: %s\n", xslFileUrl, ex.getMessage()), ex);

					return;
				} catch (IOException ex) {
					throw new Camtasia2JsonException(String.format("I/O fehler bei der XSL Transformation für die Datei \"%s\": %s\n", xslFileUrl, ex.getMessage()), ex);
				}

				try {
					boolean reformatJson = !Main.DEBUG;

					if (outputToFile) {
						processor.writeJson(destFileName, reformatJson);
						System.out.printf("Zieldatei: \"%s\"\n", destFileName);
						System.out.println("Tranformationsvorgang erfolgreich.");
					} else {
						processor.writeJson(System.out, reformatJson);
						// Bei der Ausgabe durch stdout gibt man besser keine Erfolgsmeldung an.
					}
				} catch (JsonProcessingException ex) {
					throw new Camtasia2JsonException(String.format("Bei der Prüfung der JSON Daten: " + ex.getMessage()), ex);
				} catch (IOException ex) {
					if (outputToFile)
						throw new Camtasia2JsonException(String.format("Beim Schreiben der Zieldatei \"%s\": %s", destFileName, ex.getMessage()), ex);
					else
						throw new Camtasia2JsonException(String.format("Beim Schreiben der Daten: %s", ex.getMessage()), ex);
				}
			}
		} catch (Camtasia2JsonException ex) {
			System.err.println("FEHLER: " + ex.getMessage());
		} catch (Exception ex) {
			System.err.println("FEHLER: Unbehandelte Ausnahme:");
			ex.printStackTrace();
		}
	}

	/**
	 * Prüft einen gegebenen Dateinamen auf Gültigkeit und wenn dort eine Datei exestiert, ob in diese geschrieben werden kann.
	 * Gibt anschließend den gegebenen Dateinamen mit einem absoluten Pfad zurück.
	 * @param destFileName Der Dateiname der geprüft werden soll.
	 * @return Der Eingabedateiname mit absolutem Pfad. Null, falls der Pfad ungültig war.
	 */
	private static String properCheckedDestFileName(String destFileName) throws Camtasia2JsonException {
		try {
			File file = new File(destFileName);
			if (file.exists() && !file.canWrite())
				throw new Camtasia2JsonException(String.format("Die Zieltdatei \"%s\" ist schreibgeschützt.", destFileName));

			return file.getCanonicalPath();
		} catch (IOException ex) {
			throw new Camtasia2JsonException(String.format("\"%s\" ist kein gültiger Pfad.", destFileName), ex);
		}
	}

	/**
	 * Parst ein XMLDocument objekt aus der Datei an der gegebenen URL.
	 * @param fileUrl Die URL die auf das XML-Eingabedokument verweist.
	 * @return Das geparste XMLDocument objekt.
	 */
	private static XMLDocument xmlDocumentFromFile(@NotNull URL fileUrl) throws Camtasia2JsonException {
		DOMParser parser = new DOMParser();
		parser.setPreserveWhitespace(true);

		try {
			parser.parse(fileUrl);
			return parser.getDocument();
		} catch (FileNotFoundException ex) {
			throw new Camtasia2JsonException(String.format("Die Datei \"%s\" wurde nicht gefunden.\n", fileUrl), ex);
		} catch (XMLParseException ex) {
			throw new Camtasia2JsonException(String.format("Die Datei \"%s\" enthält ungültige XML Daten: %s Zeile: %d, Spalte: %d.\n", fileUrl, ex.getMessage(), ex.getLineNumber(0), ex.getColumnNumber(0)), ex);
		} catch (SAXException ex) {
			throw new Camtasia2JsonException(String.format("Die Datei \"%s\" enthält ungültige XML Daten: %s\n", fileUrl, ex.getMessage()), ex);
		} catch (IOException ex) {
			throw new Camtasia2JsonException(String.format("Die Datei \"%s\" konnte nicht verarbeitet werden: %s\n", fileUrl, ex.getMessage()), ex);
		}
	}

	/**
	 * Gibt ein URL Objekt zurück. Wenn die angegebene URL Zeichenfolge keine gültige URL ist, wird sie in eine gültige
	 * Datei-URL konvertiert.
	 * @param urlString Die URL als Zeichenfolge.
	 * @return Das resultierende URL objekt.
	 */
	private static URL fixedFileUrl(@NotNull String urlString) {
		try {
			return new URL(urlString);
		} catch (MalformedURLException ex) {
			File file = new File(urlString);

			try {
				String path = file.getAbsolutePath();

				// Windows Pfad in ein URL taugliches Format konvertieren
				String fileSeparator = System.getProperty("file.separator");
				if (fileSeparator.length() == 1) {
					char separator = fileSeparator.charAt(0);
					if (separator != '/')
						path = path.replace(separator, '/');
					if (path.charAt(0) != '/')
						path = '/' + path;
				}

				path = "file://" + path;
				return new URL(path);
			} catch (MalformedURLException e) {
				throw new IllegalArgumentException(e);
			}
		}
	}

	/**
	 * Gibt einen Hilfetext zur verwendung der Anwendung aus.
	 */
	private static void printHelpText() {
		System.out.println("Camtasia2Json (c) David Kay Posmyk <KayPosmyk@gmx.de> " + APP_VERSION);
		System.out.println();
		System.out.println("Verwendung: ");
		System.out.println("  CamtasiaToJson.jar Projektdatei [Ausgabedatei] [XSL-Stylesheet]");
		System.out.println();
		System.out.println("Parameter: ");
		System.out.println("  Projektdatei    Dateipfad oder URL zur Camtasia Studio Projektdatei.");
		System.out.println("  Ausgabedatei    Dateipfad der Ausgabedatei.");
		System.out.println("                  Bei Nichtangabe erfolgt Ausgabe über stdout.");
		System.out.println("  XSL-Stylesheet  Dateipfad oder URL zum XSL-Stylesheet.");

		return;
	}
}

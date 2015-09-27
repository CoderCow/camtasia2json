/**
 * Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
 * Lizenz von Creative Commons zur Verfügung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/
 *
 * @author David Kay Posmyk <KayPosmyk@gmx.de>
 */

package de.hs_duesseldorf.medien.app.camtasia2json;

import com.fasterxml.jackson.core.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.sun.istack.internal.NotNull;
import oracle.xml.parser.v2.*;

import java.io.*;
import java.net.URL;
import java.util.Locale;

/**
 * Wandelt eine Camtasia Studio Projektdatei in eine ePlayer kompatible JSON Datei um, wobei diese
 * durch weitere zusätzliche Features angereichert wird.
 */
public class Camtasia2JsonProcessor {
	private final XSLProcessor xslProcessor;
	private final XSLStylesheet xslStylesheet;
	private byte[] transformationResult;

	/**
	 * Initialisiert eine neue Instanz mit dem gegebenen XSL-Stylesheet.
	 * @param xslDocument Das XML Dokument das ein XSL-Stylesheet repräsentiert.
	 * @param xslBaseUrl Die URL die die Basis für relative include/import Referenzen darstellt.
	 * @throws XSLException Das XSL-Stylesheet ist fehlerhaft.
	 */
	public Camtasia2JsonProcessor(@NotNull XMLDocument xslDocument, @NotNull URL xslBaseUrl) throws XSLException {
		if (xslDocument == null)
			throw new IllegalArgumentException("xslDocument can not be null.");

		this.xslProcessor = new XSLProcessor();
		// Sprache der Fehlermeldungen festlegen
		this.xslProcessor.setLocale(Locale.GERMAN);
		this.xslProcessor.setBaseURL(xslBaseUrl);
		this.xslProcessor.showWarnings(true);

		this.xslStylesheet = this.xslProcessor.newXSLStylesheet(xslDocument);
	}

	/**
	 * Liest und transformiert ein Camtasia Studio Projekt und schreibt es in den internen Buffer.
	 * @param camtasiaProject Das Camtasia Studio Projekt als XML Dokument.
	 * @throws IOException Das Transformieren des Projekts ist fehlgeschlagen.
	 * @throws XSLException Das Transformieren des Projekts ist fehlgeschlagen.
	 */
	public void readCamtasiaProject(@NotNull XMLDocument camtasiaProject) throws IOException, XSLException {
		if (camtasiaProject == null)
			throw new IllegalArgumentException("camtasiaProject can not be null.");

		ByteArrayOutputStream resultStream = null;
		try {
			resultStream = new ByteArrayOutputStream(89200);
			this.xslProcessor.processXSL(this.xslStylesheet, camtasiaProject, resultStream);
			resultStream.flush();

			this.transformationResult = resultStream.toByteArray();
		} finally {
			if (resultStream == null)
				resultStream.close();
		}
	}

	/**
	 * Schreibt das transformierte Camtasia Studio Projekt als im JSON Format in die Datei mit dem gegebenen Namen.
	 * @param fileName Der Dateiname der Zieldatei.
	 * @param reformatJson Legt fest, ob die aus der Transformation resultierenden JSON Daten reformatiert werden sollen.
	 * @throws IOException Das Schreiben der JSON Datei ist fehlgeschlagen.
	 */
	public void writeJson(@NotNull String fileName, boolean reformatJson) throws IOException {
		if (fileName == null)
			throw new IllegalArgumentException("fileName can not be null.");

		FileOutputStream outputStream = null;
		try {
			outputStream = new FileOutputStream(fileName);
			this.writeJson(outputStream, reformatJson);
		} finally {
			if (outputStream != null)
				outputStream.close();
		}
	}

	/**
	 * Schreibt das transformierte Camtasia Studio Projekt als im JSON Format in den gegebenen Datenstrom.
	 * @param outputStream Der Datenstrom in den die JSON Daten geschrieben werden sollen.
	 * @param reformatJson Legt fest, ob die aus der Transformation resultierenden JSON Daten reformatiert werden sollen.
	 * @throws IOException Das Schreiben der JSON Datei ist fehlgeschlagen.
	 */
	public void writeJson(@NotNull OutputStream outputStream, boolean reformatJson)
		throws IOException, JsonParseException, JsonProcessingException
	{
		if (outputStream == null)
			throw new IllegalArgumentException("outputStream can not be null.");
		if (this.transformationResult == null)
			throw new IllegalStateException("No data have been read into the buffer yet.");

		if (!reformatJson) {
			outputStream.write(this.transformationResult);
		} else {
			ObjectMapper jsonMapper = new ObjectMapper();
			jsonMapper.enable(SerializationFeature.INDENT_OUTPUT);
			JsonFactory jsonFactory = new JsonFactory();
			jsonFactory.setCodec(jsonMapper);

			JsonGenerator jsonGenerator = jsonFactory.createGenerator(outputStream);
			JsonParser jsonParser = jsonFactory.createParser(this.transformationResult);
			// JSON Ausgabe einlesen und dadurch auf Gültigkeit prüfen, danach sofort wieder schreiben und dabei
			// neu formatieren.
			try {
				jsonGenerator.writeTree(jsonParser.readValueAsTree());
			} catch (JsonProcessingException ex) {
				// Zumindest das originale JSON ausgeben um den Fehler schneller auffindbar zu machen.
				outputStream.write(this.transformationResult);
				throw ex;
			}
		}
	}

	/**
	 * Legt den Datenstrom für Warn- und Fehlermeldungen fest.
	 * @param stream Der Datenstrom.
	 */
	public void setErrorStream(PrintStream stream) {
		try {
			this.xslProcessor.setErrorStream(stream);
		} catch (IOException ex) {
			// Wird wahrscheinlich niemals geworfen.
			ex.printStackTrace();
		}
	}
}

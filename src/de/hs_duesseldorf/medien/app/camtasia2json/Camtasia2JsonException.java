/**
 * Diese Datei ist Teil der Anwendung "Camtasia2Json". Sie wird unter der "Attribution-NonCommercial-ShareAlike 4.0 International"
 * Lizenz von Creative Commons zur Verfügung gestellt, die hier zu finden ist: http://creativecommons.org/licenses/by-nc-sa/4.0/
 *
 * @author David Kay Posmyk <KayPosmyk@gmx.de>
 */

package de.hs_duesseldorf.medien.app.camtasia2json;

/**
 * Geworfen, wenn in der Camtasia2Json Hauptanwendung ein Fehler auftritt.
 */
public class Camtasia2JsonException extends Exception {
	public Camtasia2JsonException() {
		this("Eine unerwarter Fehler ist aufgetreten.");
	}

	public Camtasia2JsonException(String message) {
		super(message);
	}

	public Camtasia2JsonException(String message, Throwable cause) {
		super(message, cause);
	}
}

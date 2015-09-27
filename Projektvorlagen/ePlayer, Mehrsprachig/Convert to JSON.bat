@ECHO OFF
SET C2J=Camtasia2Json.jar
SET CAMTASIA_PROJECT=../Projekt.camproj
SET JSON_OUT_DIR=../publish
SET JSON_OUT_FILE=%JSON_OUT_DIR%/1.json
CD Camtasia2Json

IF NOT EXIST "%JSON_OUT_DIR%" MKDIR "%JSON_OUT_DIR%"
java -jar "%C2J%" "%CAMTASIA_PROJECT%" "%JSON_OUT_FILE%"
PAUSE
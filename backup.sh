#!/bin/bash
filename=$(date +%Y%m%d-%H%Mz.zip)
rm -r backup 2> /dev/null
mkdir backup
echo "Created Backup folder"
pg_dump production > backup/dump.sql
echo "Genereted SQL Dump"
cp -r public backup/
echo "Copied static file"
zip -q -r $filename backup/
echo "Completed zipping"
rm -r backup
echo "Removed backup directory"
access_token=$(curl -s --request POST 'https://oauth2.googleapis.com/token' --form 'client_id=<Client ID>' --form 'client_secret=<Client Secret>' --form 'refresh_token=<Refresh Token>' --form 'grant_type=refresh_token' | jq -M -r '.access_token')
echo "Got access token: $access_token"
folder_result=$(curl -s --request GET 'https://www.googleapis.com/drive/v3/files?q=name%20%3D%20%27Aslam%20Backups%27%20and%20mimeType%20%3D%20%27application%2Fvnd.google-apps.folder%27%20and%20trashed%3Dfalse' --header "Authorization: Bearer $access_token" | jq -M '.files')
echo "Searched the folder exists: $folder_result"
result_count=$(echo $folder_result | jq -M '. | length')
if [ $result_count -eq 0 ];
then
        echo "Folder doesn't exists"
        folder_id=$(curl -s --request POST 'https://www.googleapis.com/drive/v3/files' --header "Authorization: Bearer $access_token" --header 'Content-Type: application/json' --data-raw '{"name": "Regal Backups","mimeType": "application/vnd.google-apps.folder"}' | jq -M -r '.id')
        echo "Folder Created: $folder_id"
else
        folder_id=$(echo $folder_result | jq -M -r '.[0].id')
        echo "Folder exists: $folder_id"
fi
curl --request POST 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart' --header "Authorization: Bearer $access_token" --form 'Metadata="{\"name\": \"'"$filename"'\",\"parents\":[\"'"$folder_id"'\"]}";type=application/json' --form "Media=@$filename"
echo "File uploaded"
mv $filename archive/


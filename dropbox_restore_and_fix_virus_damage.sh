while IFS='$\n' read -r filename; do

REVISION=`curl -X POST https://api.dropboxapi.com/2/files/list_revisions     --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN"     --header "Content-Type: application/json"     --data "{\"path\": \"$filename\",\"mode\": \"path\",\"limit\": 10}" | jq -r ".entries[0].rev"`
echo ...
# Restore it
echo "Restoring... $filename"
curl -X POST https://api.dropboxapi.com/2/files/restore \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"$filename\",\"rev\": \"$REVISION\"}"
echo ...
# Delete corrupted file: file+virus_sufix
echo "Deleting... $filename$VIRUS_SUFIX"
curl -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"$filename$VIRUS_SUFIX\"}"

done





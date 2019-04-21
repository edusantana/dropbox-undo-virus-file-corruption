# dropbox undo virus file corruption

This repository describe how I have restored my wife's dropbox from a ransomware virus.

# dropbox-undo-virus-file-corruption

My wife's computer got an virus, and it affected all documents and the Dropbox's files.

The virus created a file manual (`RJMTQ-MANUAL.TXT`) in each folder:

```
---=    GANDCRAB V5.2    =--- 

***********************UNDER NO CIRCUMSTANCES DO NOT DELETE THIS FILE, UNTIL ALL YOUR DATA IS RECOVERED***********************

	*****FAILING TO DO SO, WILL RESULT IN YOUR SYSTEM CORRUPTION, IF THERE ARE DECRYPTION ERRORS*****

Attention! 

All your files, documents, photos, databases and other important files are encrypted and have the extension: .RJMTQ

The only method of recovering files is to purchase an unique private key. Only we can give you this key and only we can recover your files.
```

The dropbox files were renamed and changed (corrupted) by the virus. On this case the `.rjmtq` was added at the end of the name of every file it changed.

As you can see in the picture bellow, if you go to dropbox file we can see that there are two versions (revisions) of the file and we can restore it:

![listando-problema-virus](https://user-images.githubusercontent.com/3603111/56471293-378cfe80-6427-11e9-9bf1-3d861c99a808.gif)

After restore, you have to rename it to the previous name. **That's all you have to do**!

# Many files

OK, the real problem is how many file you have to restore. I needed to do it for more than 2.000 files. That's when I had automate the task.

## Description of the automated solution

We have to:

1. Create a token key to call Dropbox API.
2. Search for file revision we want to restore by the file sufix.
3. For each file and revision: restore file and delete corrupted file

**NOTE**: The right sequence is important, if we restore all file first and the remove corrupted files latter we could end up getting into Dropbox file limit. So we have to restore and delete one file at time.

# The solution

## Step by Step

The first step is to create an client token, [see the docs](https://www.dropbox.com/developers/reference/getting-started#app%20console). Go to [https://www.dropbox.com/developers/apps](https://www.dropbox.com/developers/apps) and create an app, and generate an token access:

![generate-token](https://user-images.githubusercontent.com/3603111/56471595-a4ee5e80-642a-11e9-9147-560dc1c491fc.gif)

Then, edit `~/.bashrs` and add it there (use your token not mine), with your VIRUS_SUFIX:

```bash
export DROPBOX_APP_ACESS_TOKEN="J6qQO1efnZkAAAAAAAAQ4KAndCrWIcl6L8_6uiXgScNUyL5lJcWPOUUxulZj-BQL"
export VIRUS_SUFIX=".rjmtq"
```

**NOTE**: It is is **VERY IMPORTANT** that you use YOUR file sufix, mine was `.rjmtq`. Is is also very important to start it with the dot.


## 2. Search for file revision we want to restore by the file sufix.

Now that we have a token we can call [Dropbox API](https://www.dropbox.com/developers/documentation/http/documentation).

Let's search files we are interest to restore and delete. Let's search files we want to DELETE, those that has the sufix.

Lets call the [search api method](https://www.dropbox.com/developers/documentation/http/documentation#files-search) to look for files that have those sufix:


```
curl -X POST https://api.dropboxapi.com/2/files/search \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"\",\"query\": \"$VIRUS_SUFIX\",\"start\": 0,\"max_results\": 1000,\"mode\": \"filename\"}"
```

The result will be a json file, we can see it better with [jq](https://stedolan.github.io/jq/):

```
curl -X POST https://api.dropboxapi.com/2/files/search \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"\",\"query\": \"$VIRUS_SUFIX\",\"start\": 0,\"max_results\": 1000,\"mode\": \"filename\"}" > ~/list.json
cat ~/list.json | jq
```

Now we have to filter only the files:

```
cat ~/list.json | jq -r '.matches[].metadata.path_display' | sed "s/$VIRUS_SUFIX$//g" > ~/list.txt
cat ~/list.txt
```

Now you have on `~/list.txt` paths of files without the VIRUS_SUFIX. Those files were at your dropbox before the virus. We are going to restore it, but we have find its last revision number before. This code will display the revision number of the first line saved at `~/list.txt`:

```
export filename=`cat ~/list.txt | head -n 1`
echo Looking for revision number of file: $filename
curl -X POST https://api.dropboxapi.com/2/files/list_revisions     --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN"     --header "Content-Type: application/json"     --data "{\"path\": \"$filename\",\"mode\": \"path\",\"limit\": 10}" | jq -r ".entries[0].rev"
```

The result will be a number such as `303e06c8eca4`. The [dropbox restore api](https://www.dropbox.com/developers/documentation/http/documentation#files-restore) will require this revision number and a path to restore it, we will use these both.

```
export filename=`cat ~/list.txt | head -n 1`
echo Looking for revision number of file: $filename
export revision=`curl -X POST https://api.dropboxapi.com/2/files/list_revisions     --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN"     --header "Content-Type: application/json"     --data "{\"path\": \"$filename\",\"mode\": \"path\",\"limit\": 10}" | jq -r ".entries[0].rev"`
curl -X POST https://api.dropboxapi.com/2/files/restore \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"$filename\",\"rev\": \"$revision\"}"
```

Now, go to your Dropbox site and see that the file was restored. Now we have to use [delete API](https://www.dropbox.com/developers/documentation/http/documentation#files-delete) to remove the file with the virus sufix:

```
curl -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"$filename$VIRUS_SUFIX\"}"
```

Go to your dropbox site and see that the file was removed.

## Restoring and removing damaged files

### Searching and listing files

Now, we need to do it with all files, not just the first. First list all files and inspect it again:

```
curl -X POST https://api.dropboxapi.com/2/files/search \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"\",\"query\": \"$VIRUS_SUFIX\",\"start\": 0,\"max_results\": 1000,\"mode\": \"filename\"}" > ~/list.json
cat ~/list.json | jq -r '.matches[].metadata.path_display' | sed "s/$VIRUS_SUFIX$//g" > ~/list.txt
```

### Restoring and deleting files

Inspect `cat ~/list.txt` and see that those are your files you want to restore. Then run `dropbox_restore_and_fix_virus_damage.sh`:

```
./dropbox_restore_and_fix_virus_damage.sh < ~/list.txt
```

![restorint-deleting-dropbox](https://user-images.githubusercontent.com/3603111/56474271-e80df900-644d-11e9-8f8e-c9643bf8a115.gif)

The search call has a limit of 1000 files to return, look at your `list.txt` file:

```
cat -n ~/list.txt
```

Rerun the search and update the file `~/list.txt` to include the next results, and rerun `dropbox_restore_and_fix_virus_damage.sh` as many time as it takes to restore all your files.

### Remove manual file

the virus also created a `RJMTQ-MANUAL.TXT` at each directory. Here's how to remove it:


```bash
MANUAL_FILE=RJMTQ-MANUAL.TXT
curl -X POST https://api.dropboxapi.com/2/files/search \
    --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"\",\"query\": \"$MANUAL_FILE\",\"start\": 0,\"max_results\": 1000,\"mode\": \"filename\"}" \
    | jq -r '.matches[].metadata.path_display' \
    | while IFS='$\n' read -r filename; do 
    curl -X POST https://api.dropboxapi.com/2/files/delete_v2 \
        --header "Authorization: Bearer $DROPBOX_APP_ACESS_TOKEN" \
        --header "Content-Type: application/json" \
        --data "{\"path\": \"$filename\"}"
    done
```


# If you need help

This is how I fixed my wife's dropbox. If need help with yours, you can contact me at gmail: eduardo.ufpb.


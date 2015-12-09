
s3cmd --acl-public put nanobox.msi nanobox-bundle.exe s3://tools.nanobox.io/installers/windows/

# saveauth ACCESS_KEY_ID  SECRET_ACCESS_KEY [NAME]
s3express.exe 'put nanobox.msi tools.nanobox.io/installers/windows/nanobox.msi -cacl:public-read' 'put nanobox-bundle.exe tools.nanobox.io/installers/windows/nanobox-bundle.exe -cacl:public-read' 'quit'

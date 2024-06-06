Anleitung
Kopieren

Entitlements


    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.de.kuehnerleben.$Name</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudDocuments</string>
    </array>
    <key>com.apple.developer.ubiquity-container-identifiers</key>
    <array>
        <string>iCloud.de.kuehnerleben.$Name</string>
    </array>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
PList

    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>$Name Language</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>de.kuehnerleben.$Name.language</string>
            </array>
            <key>LSTypeIsPackage</key>
            <true/>
            <key>NSDocumentClass</key>
            <string></string>
        </dict>
    </array>
    <key>NSUbiquitousContainers</key>
    <dict>
        <key>iCloud.de.kuehnerleben.$Name</key>
        <dict>
            <key>NSUbiquitousContainerIsDocumentScopePublic</key>
            <true/>
            <key>NSUbiquitousContainerName</key>
            <string>$Name</string>
            <key>NSUbiquitousContainerSupportedFolderLevels</key>
            <string>Any</string>
        </dict>
    </dict>
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>LSTypeIsPackage</key>
            <true/>
            <key>UTTypeConformsTo</key>
            <array>
                <string>com.apple.package</string>
            </array>
            <key>UTTypeDescription</key>
            <string>$Name Language</string>
            <key>UTTypeIcons</key>
            <dict/>
            <key>UTTypeIdentifier</key>
            <string>de.kuehnerleben.$Name.language</string>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>language</string>
                </array>
                <key>public.mime-type</key>
                <array>
                    <string>application/language</string>
                </array>
            </dict>
        </dict>
    </array>
    

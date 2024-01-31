macOS needs you to request a specific entitlement in order to access the network. To do that open macos/Runner/DebugProfile.entitlements and add the following key-value pair.

<key>com.apple.security.network.client</key>
<true/>
<true/>
Then do the same thing in macos/Runner/Release.entitlements.
# Peer Connect

&nbsp;

## Peer Connect iOS mobile app
&nbsp;
&nbsp;

### Peer Connect is an app which applies a Swift's extension, MultiPeer Connectivity, to let users chat with nearby devices.  The extension uses bluetooth and wifi to make connections between devices.  
&nbsp;

### The app starts to browse for the other devices when the user presses the start button.  It also starts to advertise the user's device for the other device to know the user is available for connections.
&nbsp;

### The devices discovered will be displayed to the user.  The user can choose up to 7 devices to connect.  Then, the app will wait for all 7 devices to respond and navigate to the chat view.  The user can end the chat anytime he wants.  If the user is the one who initiates the chat, by pressing the end chat button, the user will disconnect all the peers, the chat will end.  If the user is the one who accepts an invitation, by pressing the end chat button will disconnect him only.  It won't affect the other peers.  The group chat can continue.  If all peers disconnected, the chat will be ended.
&nbsp;

### The app only permit one chat at anytime.  If there are incoming connections during the chat, the user's device will refuse the connections automatically.  It will accept connections again when the chat ended.  
&nbsp;

### The chat is entirely peer to peer.  There is no central server involved.  I'm still thinking if I'll keep the chat records using Core Data.  
&nbsp;

### I am still writing a function to send files, data between devices.
&nbsp;

<img src=".\images\peerConnect_01a.jpg" alt="application home screenshot" style="width:250px; margin-left: auto; margin-right: auto; display: block;" />

&nbsp;
<center> Home screen </center>
&nbsp;
&nbsp;

<img src=".\images\peerConnect_03.jpg" alt="choose peer screenshot" style="width:250px; margin-left: auto; margin-right: auto; display: block;" />

&nbsp;
<center> The app displays a list of peers that is available to connect.  The user can select up to 7 peers. </center>
&nbsp;
&nbsp;

<img src=".\images\peerConnect_06.jpg" alt="peer status screenshot" style="width:250px; margin-left: auto; margin-right: auto; display: block;" />

&nbsp;
<center> The app allows the peers to choose to accept or reject the connection. </center>
&nbsp;
&nbsp;

<img src=".\images\peerConnect_04.jpg" alt="peer status screenshot" style="width:250px; margin-left: auto; margin-right: auto; display: block;" />

&nbsp;
<center> The app shows the status of the connections.  If it is ready, the app will navigate to the chat view. </center>
&nbsp;
&nbsp;

<img src=".\images\peerConnect_07.jpg" alt="peer status screenshot" style="width:250px; margin-left: auto; margin-right: auto; display: block;" />

&nbsp;
<center> The app also displays the connected peers and the group members in the chat view. </center>
&nbsp;
&nbsp;

## Programming Style

&nbsp;

1. The app is written in SwiftUI.  It follows Modern View Controller pattern.  

2. The connection manager class is used to deal with all connection related issues.  It imports the Multipeer Connectivity module and use it to discover peers, advertise user device, connect peers, listen for incoming connections and send messages.  The views retrieve peer status infomation and the chat messages from the connection manager to display to the user.

3. The app makes use of the @observedObject and @environmentObject to listen for various updates from the connection manager.  This is very important for this app because a lot functions depend on the change of the information from the connection.  Like, the app will navigate to the chat view after the connection manager receive all responses to the invitations.  

4. In order to make it more convenient for the whole app to response to user initiated activities, I created an app state enum to represent different stages of the app.  Most part of the app need to accomodate to different app states, like when to show an alert, when to end the chat, show who are connected with the user's device.  Most of the time, the connection manager makes the decision of the change of the app states.  Sometimes, the views decide, like the user press the end chat button, the app is changed to the end chat state.


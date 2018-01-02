
Namespace std.socket

#If __TARGET__="windows"
#Import "<libWs2_32.a>"
#Endif

#Import "native/socket.cpp"
#Import "native/socket.h"

Extern private

#rem monkeydoc @hidden
#end
Function socket_init:int()="bbSocket::init"

#rem monkeydoc @hidden
#end
Function socket_connect:Int( hostname:CString,service:CString,type:Int,flags:int )="bbSocket::connect"

#rem monkeydoc @hidden
#end
Function socket_bind:Int( hostname:CString,service:CString,flags:int )="bbSocket::bind"

#rem monkeydoc @hidden
#end
Function socket_listen:Int( hostname:CString,service:CString,backlog:Int,flags:int )="bbSocket::listen"

#rem monkeydoc @hidden
#end
Function socket_accept:Int( socket:Int )="bbSocket::accept"

#rem monkeydoc @hidden
#end
Function socket_close( socket:Int )="bbSocket::close"

#rem monkeydoc @hidden
#end
Function socket_send:Int( socket:Int,data:Void Ptr,size:Int )="bbSocket::send"

#rem monkeydoc @hidden
#end
Function socket_recv:Int( socket:Int,data:Void Ptr,size:Int )="bbSocket::recv"

#rem monkeydoc @hidden
#end
Function socket_sendto:Int( socket:Int,data:Void Ptr,size:Int,addr:Void ptr,addrlen:Int )="bbSocket::sendto"

#rem monkeydoc @hidden
#end
Function socket_recvfrom:Int( socket:Int,data:Void Ptr,size:Int,addr:Void ptr,addrlen:Int Ptr )="bbSocket::recvfrom"

#rem monkeydoc @hidden
#end
Function socket_setopt( socket:Int,opt:String,value:Int )="bbSocket::setopt"

#rem monkeydoc @hidden
#end
Function socket_getopt:Int( socket:Int,opt:String )="bbSocket::getopt"

#rem monkeydoc @hidden
#end
Function socket_cansend:Int( socket:Int )="bbSocket::cansend"

#rem monkeydoc @hidden
#end
Function socket_canrecv:Int( socket:Int )="bbSocket::canrecv"

#rem monkeydoc @hidden
#end
Function socket_getsockaddr:Int( socket:Int,addr:Void Ptr,addrlen:Int Ptr )="bbSocket::getsockaddr"

#rem monkeydoc @hidden
#end
Function socket_getpeeraddr:Int( socket:Int,addr:Void Ptr,addrlen:Int Ptr )="bbSocket::getpeeraddr"

#rem monkeydoc @hidden
#end
Function socket_sockaddrname:Int( addr:Void Ptr,addrlen:Int,host:libc.char_t Ptr,service:libc.char_t Ptr )="bbSocket::sockaddrname"

#rem monkeydoc @hidden
#end
Function socket_select:Int( n_read:Int,r_socks:Int ptr,n_write:Int,w_socks:Int Ptr,n_except:Int,e_socks:Int Ptr,millis:Int )="bbSocket::select"

Private

Global _init:=socket_init()

Public

#rem monkeydoc The SocketType enum.

| SocketType	| Description
|:--------------|:-----------
| `Stream`		| Reliable stream, eg: TCP.
| `Datagram`	| Unreliable datagrams, eg: UDP.

#end
Enum SocketType
	Stream=0
	Datagram=1
End

#rem monkeydoc The SocketFlags enum.

| SocketFlags	| Description
|:--------------|:-----------
| `Passive`		| for Bind and Listen. Indicates socket accepts connections from any address. If not set, socket accepts loopback connections only.
| `Ipv4`		| for Connect, Bind and Listen. Socket can be an ip4 socket.
| `Ipv6`		| for Connect, Bind and Listen. Socket can be an ip6 socket.

#end
Enum SocketFlags
	Passive=1
	Ipv4=2
	Ipv6=4
End

#rem monkeydoc The SocketAddress class.

A socket address encapsulates the hostname and service of a socket.

Socket address objects are returned by the [[Socket.Address]] and [[Socket.PeerAddress]] properties, and indirectly returned by [[Socket.ReceiveFrom]].

#end
Class SocketAddress

	#rem monkeydoc Creates a new empty socket address.
	
	The new socket address can be used with [[Socket.ReceiveFrom]].
	 
	#end
	Method New()
	End

	#rem monkeydoc Creates a copy of an existing socket address.
	
	Creates and returns a copy of `address`.
	
	#end
	Method New( address:SocketAddress )
		_addr=address._addr.Slice( 0 )
		_addrlen=address._addrlen
		_host=address._host
		_service=address._service
		_dirty=address._dirty
	End

	#rem monkeydoc The hostname represented by the address.
	
	Returns an empty string if the address is invalid.
	
	#end
	Property Host:String()
		Validate()
		Return _host
	End
	
	#rem monkeydoc The service represented by the address.

	Returns an empty string if the address is invalid.
	
	#end
	Property Service:String()
		Validate()
		Return _service
	End

	#rem monkeydoc Comparison operator.
	#end	
	Operator<=>:Int( address:SocketAddress )
		Local n:=libc.memcmp( _addr.Data,address._addr.Data,Min( _addrlen,address._addrlen ) )
		If Not n Return _addrlen-address._addrlen
		Return n
	End
	
	#rem monkeydoc Converts the address to a string.
	#end
	Method To:String()
		Return Host+":"+Service
	End
	
	Private
	
	Field _addr:=New Byte[128]
	Field _addrlen:Int=0

	Field _host:String=""
	Field _service:String=""
	Field _dirty:Bool=False	
	
	Method Validate()
		If Not _dirty Return
		
		Local host:=New libc.char_t[1024]
		Local service:=New libc.char_t[80]
		
		If socket_sockaddrname( _addr.Data,_addrlen,host.Data,service.Data )>=0
			_host=String.FromCString( host.Data )
			_service=String.FromCString( service.Data )
		Else
			_host=""
			_service=""
		Endif
		
		_dirty=False
	End

	Property Addr:Void Ptr()
		Return _addr.Data
	End
	
	Property Addrlen:Int()
		Return _addrlen
	End
	
	Method Update( addrlen:Int )
		_addrlen=addrlen
		If _addrlen
			_dirty=True
			Return
		Endif
		_host=""
		_service=""
		_dirty=False
	End
	
End

#rem monkeydoc The Socket class.

The socket class provides a thin wrapper around native Winsock and BSD sockets.

Sockets support asynchronous programming through the use of fibers. To connect, send or receive asynchronously, simply run the relevant socket code on its own fiber. Control will be returned to the 'main' gui fiber will the operation is busy.

Sockets are ipv4/ipv6 compatible.

#end
Class Socket Extends std.resource.Resource

	#rem Not on Windows...
	
	#rem monkeydoc The number of bytes that be sent to the socket without it blocking.
	#end
	Property CanSend:Int()
		If _socket=-1 Return 0
		
		Return socket_cansend( _socket )
	End
	#end
	
	#rem  monkeydoc True if socket has been closed.
	#end
	Property Closed:Bool()
		Return _socket=-1
	End

	#rem monkeydoc True if socket is connected to peer.
	#end
	Property Connected:bool()
		If _socket=-1 Return False

		Local read:=_socket
		
		Local r:=socket_select( 1,Varptr read,0,Null,0,Null,0 )
		
		If r=1 Return socket_canrecv( _socket )<>0
		
		Return r=0
	End
	
	#rem monkeydoc The number of bytes that can be received from the socket without blocking.
	#end
	Property CanReceive:Int()
		If _socket=-1 Return 0
		
		Return socket_canrecv( _socket )
	End
	
	#rem monkeydoc The address of the socket.
	#end
	Property Address:SocketAddress()
		If _socket=-1 Return Null
	
		If Not _addr
			Local addrlen:Int=128
			_addr=New SocketAddress
			Local n:=socket_getsockaddr( _socket,_addr.Addr,Varptr addrlen )
			_addr.Update( n>=0 ? addrlen Else 0 )
		Endif
		
		Return _addr
	End
	
	#rem monkeydoc The address of the socket peer.
	#end
	Property PeerAddress:SocketAddress()
		If _socket=-1 Return Null

		If Not _peer
			Local addrlen:Int=128
			_peer=New SocketAddress
			Local n:=socket_getpeeraddr( _socket,_peer.Addr,Varptr addrlen )
			_peer.Update( n>=0 ? addrlen Else 0 )
		Endif
		
		Return _peer
	End

	#rem monkeydoc Accepts a new incoming connection on a listening socket.
	
	Returns null if there was an error, otherwise blocks until an incoming connection has been made.
	
	@return new incomnig connection or null if there was an error.
	
	#end
	Method Accept:Socket()
		If _socket=-1 Return Null
	
		Local socket:=socket_accept( _socket )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Closes a socket.
	
	Once closed, a socket should not be used anymore.
	
	#end	
	Method Close()
		
		Discard()
	End
	
	#rem monkeydoc Sends data on a connected socket.

	Writes `size` bytes to the socket.
	
	Returns the number of bytes actually written.
	
	Can return less than `size` if the socket has been closed by the peer or if an error occured.
	
	@param buf The memory buffer to write data from.
	
	@param size The number of bytes to write to the socket.
	
	@return The number of bytes actually written.
	
	#end
	Method Send:Int( data:Void Ptr,size:Int )
		If _socket=-1 Return 0
		
		Return socket_send( _socket,data,size )
	End
	
	Method SendTo:Int( data:Void Ptr,size:Int,address:SocketAddress )
		If _socket=-1 Return 0
		
		DebugAssert( address.Addrlen,"SocketAddress is invalid" )
		
		Return socket_sendto( _socket,data,size,address.Addr,address.Addrlen )
	End
	
	#rem monkeydoc Receives data on a connected socket.
	
	Reads at most `size` bytes from the socket.
	
	Returns 0 if the socket has been closed by the peer.
	
	Can return less than `size`, in which case you may have to read again if you know there's more data coming.
	
	@param buf The memory buffer to read data into.
	
	@param size The number of bytes to read from the socket.
	
	@return The number of bytes actually read.
	
	#end
	Method Receive:Int( data:Void Ptr,size:Int )
		If _socket=-1 Return 0
	
		Return socket_recv( _socket,data,size )
	End
	
	Method ReceiveFrom:Int( data:Void Ptr,size:Int,address:SocketAddress )
		If _socket=-1 Return 0
		
		Local addrlen:Int=128
		
		Local n:=socket_recvfrom( _socket,data,size,address.Addr,Varptr addrlen  )
		
		address.Update( n>=0 ? addrlen Else 0 )
		
		Return n
	End
	
	#rem monkeydoc Sets a socket option.

	Currently, only "TCP_NODELAY" is supported, which should be 1 to enable, 0 to disable.
	
	#end
	Method SetOption( opt:String,value:Int )
		If _socket=-1 Return
	
		socket_setopt( _socket,opt,value )
	End
	
	#rem monkeydoc Gets a socket option.
	#end
	Method GetOption:Int( opt:String )
		If _socket=-1 Return -1
	
		Return socket_getopt( _socket,opt )
	End

	#rem monkeydoc Creates a connected socket.
	
	Attempts to connect to the host at `hostname` and service at `service` and returns a new connected socket if successful.
	
	The socket `type` should be SocketType.Stream (the default) is connecting to stream server, or SocketType.DataGram if connecting to a datagram server.
	
	Returns null upon failure.
	
	@return A new socket.
	
	#end	
	Function Connect:Socket( hostname:String,service:String,type:SocketType=SocketType.Stream,flags:SocketFlags=Null )

		Local socket:=socket_connect( hostname,service,type,flags )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Creates a datagram server socket.
	
	Returns a new datagram server socket bound to 'service' if successful.
	
	`service` can also be an integer port number.
	
	Returns null upon failure.

	@return A new socket.
	
	#end
	Function Bind:Socket( service:String,flags:SocketFlags=SocketFlags.Passive )
	
		Local socket:=socket_bind( "",service,flags )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End
	
	#rem monkey @deprecated
	#end
	Function Bind:Socket( hostname:String,service:String )
		
		Local socket:=socket_bind( "",service,1 )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End
		

	#rem monkeydoc Creates a stream server socket and listens on it.
	
	Returns a new stream server socket listening at `service` if successful.
	
	`service` can also be an integer port number.
	
	Returns null upon failure.

	@return A new socket.
	
	#end
	Function Listen:Socket( service:String,backlog:Int=32,flags:SocketFlags=SocketFlags.Passive )

		Local socket:=socket_listen( "",service,backlog,flags )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkey @deprecated
	#end
	Function Listen:Socket( hostname:String,service:String,backlog:Int=128 )
		
		Local socket:=socket_listen( "",service,backlog,1 )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End
	
	Protected

	#rem monkeydoc @hidden
	#end	
	Method OnDiscard() Override
		
		socket_close( _socket )
		_socket=-1
		_addr=Null
		_peer=null
	End
	
	#rem  monkeydoc @hidden
	#end
	Method OnFinalize() Override
		
		socket_close( _socket )
	End
	
	Private
	
	Field _socket:Int=-1
	Field _addr:SocketAddress
	Field _peer:SocketAddress
	
	Method New( socket:Int )

		_socket=socket
	End

End

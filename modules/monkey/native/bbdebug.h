
#ifndef BB_DEBUG_H
#define BB_DEBUG_H

#include "bbstring.h"

struct bbDBFiber;
struct bbDBFrame;
struct bbDBVarType;
struct bbDBVar;

inline bbString bbDBType( const void *p ){ return "Void"; }
inline bbString bbDBType( bbBool *p ){ return "Bool"; }
inline bbString bbDBType( bbByte *p ){ return "Byte"; }
inline bbString bbDBType( bbUByte *p ){ return "UByte"; }
inline bbString bbDBType( bbShort *p ){ return "Short"; }
inline bbString bbDBType( bbUShort *p ){ return "UShort"; }
inline bbString bbDBType( bbInt *p ){ return "Int"; }
inline bbString bbDBType( bbUInt *p ){ return "UInt"; }
inline bbString bbDBType( bbLong *p ){ return "Long"; }
inline bbString bbDBType( bbULong *p ){ return "ULong"; }
inline bbString bbDBType( bbFloat *p ){ return "Float"; }
inline bbString bbDBType( bbDouble *p ){ return "Double"; }
inline bbString bbDBType( bbString *p ){ return "String"; }

inline bbString bbDBValue( void *p ){ return "?????"; }
inline bbString bbDBValue( bbBool *p ){ return *p ? "True" : "False"; }
inline bbString bbDBValue( bbByte *p ){ return bbString(*p); }
inline bbString bbDBValue( bbUByte *p ){ return bbString(*p); }
inline bbString bbDBValue( bbShort *p ){ return bbString(*p); }
inline bbString bbDBValue( bbUShort *p ){ return bbString(*p); }
inline bbString bbDBValue( bbInt *p ){ return bbString(*p); }
inline bbString bbDBValue( bbUInt *p ){ return bbString(*p); }
inline bbString bbDBValue( bbLong *p ){ return bbString(*p); }
inline bbString bbDBValue( bbULong *p ){ return bbString(*p); }
inline bbString bbDBValue( bbFloat *p ){ return bbString(*p); }
inline bbString bbDBValue( bbDouble *p ){ return bbString(*p); }
extern bbString bbDBValue( bbString *p );

template<class T> bbString bbDBType(){
	return bbDBType( (T*)0 );
}

template<class T> bbString bbDBType( bbGCVar<T> *p ){ return bbDBType<T*>(); }
template<class T> bbString bbDBValue( bbGCVar<T> *p ){ T *t=p->get();return t ? bbDBValue( &t ) : "Null"; }

template<class T> bbString bbDBType( T **p ){ return bbDBType<T>()+" Ptr"; }
template<class T> bbString bbDBValue( T **p ){ char buf[64];sprintf( buf,"$%p",*p );return buf; }

struct bbDBVarType{
	virtual bbString type()=0;
	virtual bbString value( void *p )=0;
};

template<class T> struct bbDBVarType_t : public bbDBVarType{

	bbString type(){
		return bbDBType( (T*)0 );
	}
	
	bbString value( void *p ){
		return bbDBValue( (T*)p );
	}
	
	static bbDBVarType_t info;
};

template<class T> bbDBVarType_t<T> bbDBVarType_t<T>::info;

struct bbDBVar{

	const char *name;
	bbDBVarType *type;
	void *var;
};

struct bbDBContext{

	bbDBFrame *frames=nullptr;
	bbDBVar *localsBuf=nullptr;
	bbDBVar *locals=nullptr;
	int stepMode;
	int stopped;

	~bbDBContext();
	
	void init();
};

namespace bbDB{

	extern int nextSeq;

	extern bbDBContext *currentContext;
	
	void init();
	
	void stop();
	
	void stopped();
	
	void error( bbString err );
	
	bbArray<bbString> stack();
	
	void emitStack();
}

struct bbDBBlock{
	bbDBVar *locals;
	bbDBBlock():locals( bbDB::currentContext->locals ){
		if( bbDB::currentContext->stepMode=='l' ) --bbDB::currentContext->stopped;
	}
	~bbDBBlock(){
		if( bbDB::currentContext->stepMode=='l' ) ++bbDB::currentContext->stopped;
		bbDB::currentContext->locals=locals;
	}
};

struct bbDBFrame : public bbDBBlock{
	bbDBFrame *succ;
	const char *decl;
	const char *srcFile;
	int srcPos;
	int seq;
	
	bbDBFrame( const char *decl,const char *srcFile ):succ( bbDB::currentContext->frames ),decl( decl ),srcFile( srcFile ),seq( ++bbDB::nextSeq ){
		bbDB::currentContext->frames=this;
		if( bbDB::currentContext->stepMode=='s' ) --bbDB::currentContext->stopped;
	}
	
	~bbDBFrame(){
		if( bbDB::currentContext->stepMode=='s' ) ++bbDB::currentContext->stopped;
		bbDB::currentContext->frames=succ;
	}
};

struct bbDBLoop : public bbDBBlock{
	bbDBLoop(){
	}
	~bbDBLoop(){
	}
};

inline void bbDBStmt( int srcPos ){
	bbDB::currentContext->frames->srcPos=srcPos;
	if( bbDB::currentContext->stopped>0 ) bbDB::stopped();
}

template<class T> void bbDBEmit( const char *name,T *var ){
	bbDBVarType *type=&bbDBVarType_t<T>::info;
	puts( (BB_T( name )+":"+type->type()+"="+type->value( var )).c_str() );
}

template<class T> void bbDBEmit( const char *name,bbGCVar<T> *p ){
	T *var=p->get();return bbDBEmit( name,&var );
}

template<class T> void bbDBLocal( const char *name,T *var ){
	bbDB::currentContext->locals->name=name;
	bbDB::currentContext->locals->type=&bbDBVarType_t<T>::info;
	bbDB::currentContext->locals->var=var;
	++bbDB::currentContext->locals;
}

#endif

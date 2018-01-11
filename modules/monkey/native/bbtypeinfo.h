
#ifndef BB_TYPEINFO_H
#define BB_TYPEINFO_H

#include "bbassert.h"
#include "bbobject.h"
#include "bbarray.h"
#include "bbfunction.h"

//struct bbClassTypeInfo;

struct bbTypeInfo{

	bbString name;
	bbString kind;
	
	bbString getName(){
		return name;
	}
	
	bbString getKind(){
		return kind;
	}
	
	virtual bbString toString();

	virtual bbTypeInfo *pointeeType();
	
	virtual bbTypeInfo *elementType();
	
	virtual int arrayRank();
	
	virtual bbTypeInfo *returnType();
	
	virtual bbArray<bbTypeInfo*> paramTypes();
	
	virtual bbTypeInfo *superType();
	
	virtual bbArray<bbTypeInfo*> interfaceTypes();
	
	virtual bbBool extendsType( bbTypeInfo *type );
	
	virtual bbArray<bbDeclInfo*> getDecls();
	
	virtual bbVariant makeEnum( int value );
	
	virtual int getEnum( bbVariant );
	
	
	bbDeclInfo *getDecl( bbString name );
	
	bbDeclInfo *getDecl( bbString name,bbTypeInfo *type );
	
	bbArray<bbDeclInfo*> getDecls( bbString name );
	
	static bbTypeInfo *getType( bbString cname );
	
	static bbArray<bbTypeInfo*> getTypes();
};

template<class T> bbTypeInfo *bbGetType();

struct bbUnknownTypeInfo : public bbTypeInfo{

	bbUnknownTypeInfo();
};

struct bbVoidTypeInfo : public bbTypeInfo{

	static bbVoidTypeInfo instance;

	bbVoidTypeInfo();
};

struct bbObjectTypeInfo : public bbTypeInfo{

	static bbObjectTypeInfo instance;

	bbObjectTypeInfo();
	
	bbTypeInfo *superType();
	
	bbBool extendsType( bbTypeInfo *type );
	
	bbArray<bbDeclInfo*> getDecls();
};

template<class T> struct bbPrimTypeInfo : public bbTypeInfo{

	bbPrimTypeInfo( bbString name ){
		this->name=name;
		this->kind="Primitive";
	}
	
};

template<class T> struct bbPointerTypeInfo : public bbTypeInfo{

	bbPointerTypeInfo(){
		this->name=bbGetType<T>()->name+" Ptr";
		this->kind="Pointer";
	}

	bbTypeInfo *pointeeType(){
		return bbGetType<T>();
	}
	
};

template<class T,int D> struct bbArrayTypeInfo : public bbTypeInfo{

	bbArrayTypeInfo(){
		this->name=bbGetType<T>()->name+"["+BB_T(",").dup(D-1)+"]";
		this->kind="Array";
	}
	
	bbTypeInfo *elementType(){
		return bbGetType<T>();
	}
	
	int arrayRank(){
		return D;
	}
};

template<class R,class...A> struct bbFunctionTypeInfo : public bbTypeInfo{

	bbFunctionTypeInfo(){
		this->name=bbGetType<R>()->name+"("+BB_T(",").join( bbArray<bbString>( { bbGetType<A>()->name... },int(sizeof...(A)) ) )+")";
		this->kind="Function";
	}
	
	bbTypeInfo *returnType(){
		return bbGetType<R>();
	}
	
	bbArray<bbTypeInfo*> paramTypes(){
		return bbArray<bbTypeInfo*>( { bbGetType<A>()... },int(sizeof...(A)) );
	}

};

template<class...A> struct bbFunctionTypeInfo<void,A...> : public bbTypeInfo{

	bbFunctionTypeInfo(){
		this->name=BB_T("Void(")+BB_T(",").join( bbArray<bbString>( { bbGetType<A>()->name... },int(sizeof...(A)) ) )+")";
		this->kind="Function";
	}
	
	bbTypeInfo *returnType(){
		return &bbVoidTypeInfo::instance;
	}
	
	bbArray<bbTypeInfo*> paramTypes(){
		return bbArray<bbTypeInfo*>( { bbGetType<A>()... },int(sizeof...(A)) );
	}

};

#define BB_GETTYPE_DECL( TYPE ) bbTypeInfo *bbGetType( TYPE const& );

BB_GETTYPE_DECL( bbBool )
BB_GETTYPE_DECL( bbByte )
BB_GETTYPE_DECL( bbUByte )
BB_GETTYPE_DECL( bbShort )
BB_GETTYPE_DECL( bbUShort )
BB_GETTYPE_DECL( bbInt )
BB_GETTYPE_DECL( bbUInt )
BB_GETTYPE_DECL( bbLong )
BB_GETTYPE_DECL( bbULong )
BB_GETTYPE_DECL( bbFloat )
BB_GETTYPE_DECL( bbDouble )
BB_GETTYPE_DECL( bbString )
BB_GETTYPE_DECL( bbCString )
BB_GETTYPE_DECL( bbVariant )

inline bbTypeInfo *bbGetType( bbObject* const& ){
	return &bbObjectTypeInfo::instance;
}

template<class T> bbTypeInfo *bbGetUnknownType(){
 	static bbUnknownTypeInfo info;
	
	return &info;
}

template<class T> bbTypeInfo *bbGetType( T const& ){
	return bbGetUnknownType<T>();
}

template<class T> bbTypeInfo *bbGetType( T* const& ){
	static bbPointerTypeInfo<T> info;
	
	return &info;
}

template<class T,int D> bbTypeInfo *bbGetType( bbArray<T,D> const& ){
	static bbArrayTypeInfo<T,D> info;
	
	return &info;
}

template<class R,class...A> bbTypeInfo *bbGetFuncType(){
	static bbFunctionTypeInfo<R,A...> info;
	
	return &info;
}

template<class R,class...A> bbTypeInfo *bbGetType( R(*)(A...) ){
	return bbGetFuncType<R,A...>();
}

template<class R,class...A> bbTypeInfo *bbGetType( bbFunction<R(A...)> const& ){
	return bbGetFuncType<R,A...>();
}

template<class T> bbTypeInfo *bbGetType( bbGCVar<T> const& ){
	return bbGetType<T*>();
}

template<> inline bbTypeInfo *bbGetType<void>(){
	return &bbVoidTypeInfo::instance;
}

template<class T> bbTypeInfo *bbGetType(){
	return bbGetType( *(T*)0 );
}

#endif

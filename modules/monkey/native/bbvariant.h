
#ifndef BB_VARIANT_H
#define BB_VARIANT_H

#include "bbtypeinfo.h"

struct bbVariant{

	template<class T,class R=typename T::bb_object_type> static bbObject *toObject( T *p ){
		return dynamic_cast<bbObject*>( p );
	}

	template<class T> static bbObject *toObject( T const& ){
		bbRuntimeError( "Variant cast failed" );
		return 0;
	}

	template<class T,class C> static T castObject( bbObject *p,typename C::bb_object_type d=0 ){
		return dynamic_cast<T>( p );
	}

	template<class T,class C> static T castObject(...){
		bbRuntimeError( "Variant cast failed" );
		return {};
	}
	
	struct RepBase{
	
		int _refs=1;
	
		virtual ~RepBase(){
		}
		
		virtual void gcMark(){
		}
		
		virtual bbTypeInfo *getType(){
			return &bbVoidTypeInfo::instance;
		}
		
		virtual bbObject *getObject(){
			return 0;
		}
		
		virtual bbVariant invoke( bbArray<bbVariant> params ){
			bbRuntimeError( "Variant is not invokable" );
			return {};
		}
	};
	
	template<class T> struct Rep : public RepBase{
	
		T value;
		
		Rep( const T &value ):value( value ){
		}
		
		virtual void gcMark(){
			bbGCMark( value );
		}
		
		virtual bbTypeInfo *getType(){
			return bbGetType<T>();
		}
		
		virtual bbObject *getObject(){
			return toObject( value );
		}
	};
	
	static RepBase _null;
	
	RepBase *_rep;
	
	void retain()const{
		++_rep->_refs;
	}
	
	void release(){
		if( !--_rep->_refs && _rep!=&_null ) delete _rep;
	}
	
	// ***** public *****
	
	bbVariant():_rep( &_null ){
	}
	
	bbVariant( const bbVariant &v ):_rep( v._rep ){
		retain();
	}
	
	template<class T> explicit bbVariant( const T &t ):_rep( new Rep<T>( t ) ){
	}
	
	template<class T> explicit bbVariant( const bbGCVar<T> &t ):_rep( new Rep<T*>( t.get() ) ){
	}
	
	~bbVariant(){
		release();
	}
	
	bbVariant &operator=( const bbVariant &v ){
		v.retain();
		release();
		_rep=v._rep;
		return *this;
	}
	
	bbTypeInfo *getType()const{
		
		return _rep->getType();
	}
	
	bbTypeInfo *getDynamicType()const{
	
		if( bbObject *obj=_rep->getObject() ) return obj->typeof();
		
		return _rep->getType();
	}
	
	operator bool()const{
		
		return _rep!=&_null;
	}
	
	template<class T> T get()const{
	
		Rep<T> *p=dynamic_cast<Rep<T>*>( _rep );
		
		if( p ) return p->value;
		
//		bbTypeInfo *type=bbGetType<T>();
		
//		if( type->kind=="Class" ){
		
			bbObject *obj=_rep->getObject();
			
			typedef typename detail::remove_pointer<T>::type C;
			
			return castObject<T,C>( obj );
//		}
		
		bbRuntimeError( "Variant cast failed" );
		
		return T{};
	}
	
	template<class T> T *_ref( typename T::bb_object_type *p=0 )const{
	
		return get<T*>();
	}
	
	template<class T> T *_ref( T *p=0 )const{
	
		Rep<T> *r=dynamic_cast<Rep<T>*>( _rep );
		
		if( !r ) bbRuntimeError( "Variant cast failed" );
		
		return &r->value;
	}
	
	template<class T> T *ref()const{
	
		return _ref<T>( 0 );
	}
	
	int enumValue()const{
	
		return getType()->getEnum( *this );
	}
	
};

extern template struct bbVariant::Rep<bbBool>;
extern template struct bbVariant::Rep<bbByte>;
extern template struct bbVariant::Rep<bbUByte>;
extern template struct bbVariant::Rep<bbShort>;
extern template struct bbVariant::Rep<bbUShort>;
extern template struct bbVariant::Rep<bbInt>;
extern template struct bbVariant::Rep<bbUInt>;
extern template struct bbVariant::Rep<bbLong>;
extern template struct bbVariant::Rep<bbULong>;
extern template struct bbVariant::Rep<bbFloat>;
extern template struct bbVariant::Rep<bbDouble>;
extern template struct bbVariant::Rep<bbString>;

inline void bbGCMark( const bbVariant &v ){

	v._rep->gcMark();
}

inline int bbCompare( const bbVariant &x,const bbVariant &y ){

	return y._rep>x._rep ? -1 : x._rep>y._rep;
}

#endif

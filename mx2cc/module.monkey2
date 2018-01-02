
Namespace mx2

#rem

Module directory structure:

baseDir:	mojo/
buildDir:	mojo/mojo.buildv1.0.3/
outputDir:	mojo/mojo.buildv1.0.3/desktop_windows_debug/
cacheDir:	mojo/mojo.buildv1.0.3/desktop_windows_debug/build
hfileDir:	mojo/mojo.buildv1.0.3/desktop_windows_debug/include
cfileDir:	mojo/mojo.buildv1.0.3/desktop_windows_debug/src

#end

Class Module
	
	Global Dirs:String[]
	
	Field name:String
	Field srcPath:String
	
	Field ident:String
	Field baseDir:String
	Field buildDir:String
	Field outputDir:String
	Field cacheDir:String
	Field hfileDir:String
	Field cfileDir:String
	
	Field afile:String
	Field rfile:String

	Field fileDecls:=New Stack<FileDecl>
	Field fileScopes:=New Stack<FileScope>
	
	Field genInstances:=New Stack<SNode>
	Field usings:=New Stack<NamespaceScope>
	Field main:FuncValue
	
	Field moduleDeps:=New StringMap<Bool>
	
	Method New( name:String,srcPath:String,version:String,profile:String )
		Self.name=name
		Self.srcPath=srcPath
		
		ident=MungPath( name )
		
		baseDir=ExtractDir( srcPath )
		
		buildDir=baseDir+name+".buildv"+version+"/"
		
		outputDir=buildDir+profile+"/"
		
		cacheDir=outputDir+"build/"

		hfileDir=outputDir+"include/"
		
		cfileDir=outputDir+"src/"
		
		afile=outputDir+name+".a"
		
		rfile=hfileDir+"_r.cpp"
	End
	
	
End


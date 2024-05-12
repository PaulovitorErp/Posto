#include "protheus.ch"

/*/{Protheus.doc} XLS2CSV
Classe para importa��o de arquivos XLS e XLSX.
@author Danilo Brito
@since 05/09/2014
@version 1.0
@obs Funcao: CargaXLS  /  Autor: Kana�m L. R. Rodrigues 
USO: Rotina de Importa��o de Extrato de Operadora Cart�o POS

@type class
/*/
CLASS XLS2CSV

    DATA cArqImp  //nome do arquivo que ser� importado 
    DATA cPathImp //pasta onde est� o arquivo que ser� importado
    DATA cArqMacro //arquivo macro que ir� processar importa��o
    DATA cArqCSV //arquivo CSV gerado pela importa��o
    DATA cTemp	//pasta temp da esta��o local
	DATA cSystem //pasta sistem do protheus
	DATA aDados //array com dados importados do arquivo

	METHOD New(cArqE) CONSTRUCTOR
	METHOD Destroy() 
	METHOD ClassName()
	
	METHOD Import() //faz processamento importa��o
	METHOD GetArray(nLinCab) //gera vetor do arquivo CSV gerado.

ENDCLASS 


//---------------------------------------------------------------
// M�todo Construtor da Classe. Passar objeto da aba.
// @param cArqE : arquivo para importa��o (ex: C:\temp\arquivo.xls)
//---------------------------------------------------------------
METHOD New(cArqE) CLASS XLS2CSV
	
	Local nPosAux := If(ValType(cArqE)=="C", RAT("\", AllTrim(cArqE)) ,0)
	
	::cArqImp 	:= If(ValType(cArqE)=="C",substr(alltrim(cArqE), nPosAux+1 ),"") //arquivo que ser� importado
	::cPathImp  := If(ValType(cArqE)=="C",substr(alltrim(cArqE), 1, nPosAux),"") //pasta do arquivo que ser� importado 
    ::cArqMacro := "XLS2DBF.XLA" //arquivo macro que ir� processar importa��o
    ::cArqCSV 	:= "" //arquivo CSV gerado pela importa��o
    ::cTemp		:= GetTempPath() //pasta temp da esta��o local
	::cSystem 	:= Upper(GetSrvProfString("STARTPATH","")) //pasta sistem do protheus
	::aDados 	:= {} //array com dados importados do arquivo
	
Return

//---------------------------------------------------------------
// Faz Processamento de Importa��o
//---------------------------------------------------------------
METHOD Import() CLASS XLS2CSV

	Local oExcelApp
	Local nPosExten := 0
	
	if empty(::cArqImp)
		Alert("Voc� deve informar um arquivo.")
		return .F.
	endif
	
	nPosExten := RAT(".", ::cArqImp)-1
	if nPosExten <= 0
		Alert("Nome do arquivo inv�lido.")
		return .F.
	endif
	
	if !(".XLS" $ upper(::cArqImp))
		Alert("Voc� deve informar um arquivo do tipo *.XLS ou *.XLSX")
		return .F.
	endif
	
	If !File(::cPathImp + ::cArqImp)
		Alert("O arquivo "+::cPathImp + ::cArqImp+" n�o foi encontrado!")      
		Return .F.
	EndIf
	
	//verifica se existe o arquivo na pasta temporaria e apaga
	If File(::cTemp + ::cArqImp)
		fErase(::cTemp + ::cArqImp)
	EndIf                 
   
	//Copia o arquivo XLS para o Temporario para ser executado
	If !AvCpyFile(::cPathImp + ::cArqImp, ::cTemp + ::cArqImp, .F.) 
		MsgInfo("Problemas na copia do arquivo "+::cPathImp + ::cArqImp+" para "+::cTemp + ::cArqImp ,"AvCpyFile()")
		Return .F.
	EndIf                                       
   
	//apaga macro da pasta tempor�ria se existir
	If File(::cTemp + ::cArqMacro)
		fErase(::cTemp + ::cArqMacro)
	EndIf

	//Copia o arquivo XLA para o Temporario para ser executado
	If !AvCpyFile(::cSystem + ::cArqMacro, ::cTemp + ::cArqMacro,.F.) 
		MsgInfo("Problemas na copia do arquivo "+::cSystem + ::cArqMacro+" para "+::cTemp + ::cArqMacro ,"AvCpyFile()")
		Return .F.
	EndIf
   
   	::cArqCSV := ::cTemp + substr(::cArqImp,1,nPosExten)+".csv" //nome arquivo csv
   
	//Exclui o arquivo antigo (se existir)
	If File(::cArqCSV)
		fErase(::cArqCSV)
	EndIf
   
	//Inicializa o objeto para executar a macro
	oExcelApp := MsExcel():New()
	//define qual o caminho da macro a ser executada
	oExcelApp:WorkBooks:Open(::cTemp + ::cArqMacro)
	//executa a macro passando como parametro da macro o caminho e o nome do excel corrente
	oExcelApp:Run(::cArqMacro+'!XLS2DBF',::cTemp,::cArqImp)
	//fecha a macro sem salvar
	oExcelApp:WorkBooks:Close('savechanges:=False')
	//sai do arquivo e destr�i o objeto
	oExcelApp:Quit()
 	oExcelApp:Destroy()

	fErase(::cTemp + ::cArqImp)//Exclui o Arquivo excel da temp
	fErase(::cTemp + ::cArqMacro) //Exclui a Macro no diretorio temporario
	
Return .T. 


//---------------------------------------------------------------
//gera vetor do arquivo CSV gerado.
//---------------------------------------------------------------
METHOD GetArray(nLinCab) CLASS XLS2CSV 
	
	Local cLinha  := ""
	Local aLinha  := {}
	Local nHandle := 0
	Default nLinCab := 0
    
	//se j� preencheu, s� retorna
	if len(::aDados) > 0
		return ::aDados
	endif
	
	if empty(::cArqCSV)
		Alert("Fa�a a importa��o primeiro do arquivo. Fun��o Import()")
		return ::aDados
	endif

	//abre o arquivo csv gerado na temp
	nHandle := Ft_Fuse(::cArqCSV)
	If nHandle == -1
	   Return ::aDados
	EndIf
	
	Ft_FGoTop()

	//Pula as linhas de cabe�alho
	While nLinCab > 0 .AND. !Ft_FEof()
	   Ft_FSkip()
	   nLinCab--
	EndDo
	
	//percorre todas linhas do arquivo csv
	While !Ft_FEof()

	   //le a linha
	   cLinha := Ft_FReadLn()
	   aLinha := {}
	   
	   //verifica se a linha est� em branco, se estiver pula
	   If Empty(AllTrim(StrTran(cLinha,';','')))
	      Ft_FSkip()
	      Loop
	   EndIf  
	   
	   //tratamentos para campos vazios
	   if SubStr(cLinha,1,1) == ";"
	   		cLinha := " "+cLinha
	   endif
	   
	   If ";;" $ cLinha
	   		While ";;" $ cLinha
		   		cLinha := StrTran(cLinha, ";;", "; ;")
			EndDo
	   EndIf
	   
	   //cria vetor e adiciona do aDados
//	   aLinha 	:= StrToKArr(cLinha, ";", .T.)
	   aLinha 	:= StrToKArr(cLinha, ";")
	   aAdd(::aDados, aLinha)
	   
	   //passa para a pr�xima linha
	   FT_FSkip()
	EndDo
	
	//libera o arquivo CSV
	FT_FUse()  
	
Return ::aDados

//---------------------------------------------------------------
//exclui arquivos tempor�rios que foram gerados.
//---------------------------------------------------------------
METHOD Destroy() CLASS XLS2CSV   

	//Exclui o arquivo antigo (se existir)
	If !empty(::cArqCSV) .AND. File(::cArqCSV)
		fErase(::cArqCSV)
	EndIf
	
	::cArqImp := "" 
    ::cPathImp := ""
    ::cArqMacro := ""
    ::cArqCSV := ""
    ::cTemp := ""
	::cSystem := ""
	::aDados := {} 
	
Return 

//---------------------------------------------------------------
// nome da classe
//---------------------------------------------------------------
METHOD ClassName() CLASS XLS2CSV
Return( "XLS2CSV" )
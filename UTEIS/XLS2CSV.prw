#include "protheus.ch"

/*/{Protheus.doc} XLS2CSV
Classe para importação de arquivos XLS e XLSX.
@author Danilo Brito
@since 05/09/2014
@version 1.0
@obs Funcao: CargaXLS  /  Autor: Kanaãm L. R. Rodrigues 
USO: Rotina de Importação de Extrato de Operadora Cartão POS

@type class
/*/
CLASS XLS2CSV

    DATA cArqImp  //nome do arquivo que será importado 
    DATA cPathImp //pasta onde está o arquivo que será importado
    DATA cArqMacro //arquivo macro que irá processar importação
    DATA cArqCSV //arquivo CSV gerado pela importação
    DATA cTemp	//pasta temp da estação local
	DATA cSystem //pasta sistem do protheus
	DATA aDados //array com dados importados do arquivo

	METHOD New(cArqE) CONSTRUCTOR
	METHOD Destroy() 
	METHOD ClassName()
	
	METHOD Import() //faz processamento importação
	METHOD GetArray(nLinCab) //gera vetor do arquivo CSV gerado.

ENDCLASS 


//---------------------------------------------------------------
// Método Construtor da Classe. Passar objeto da aba.
// @param cArqE : arquivo para importação (ex: C:\temp\arquivo.xls)
//---------------------------------------------------------------
METHOD New(cArqE) CLASS XLS2CSV
	
	Local nPosAux := If(ValType(cArqE)=="C", RAT("\", AllTrim(cArqE)) ,0)
	
	::cArqImp 	:= If(ValType(cArqE)=="C",substr(alltrim(cArqE), nPosAux+1 ),"") //arquivo que será importado
	::cPathImp  := If(ValType(cArqE)=="C",substr(alltrim(cArqE), 1, nPosAux),"") //pasta do arquivo que será importado 
    ::cArqMacro := "XLS2DBF.XLA" //arquivo macro que irá processar importação
    ::cArqCSV 	:= "" //arquivo CSV gerado pela importação
    ::cTemp		:= GetTempPath() //pasta temp da estação local
	::cSystem 	:= Upper(GetSrvProfString("STARTPATH","")) //pasta sistem do protheus
	::aDados 	:= {} //array com dados importados do arquivo
	
Return

//---------------------------------------------------------------
// Faz Processamento de Importação
//---------------------------------------------------------------
METHOD Import() CLASS XLS2CSV

	Local oExcelApp
	Local nPosExten := 0
	
	if empty(::cArqImp)
		Alert("Você deve informar um arquivo.")
		return .F.
	endif
	
	nPosExten := RAT(".", ::cArqImp)-1
	if nPosExten <= 0
		Alert("Nome do arquivo inválido.")
		return .F.
	endif
	
	if !(".XLS" $ upper(::cArqImp))
		Alert("Você deve informar um arquivo do tipo *.XLS ou *.XLSX")
		return .F.
	endif
	
	If !File(::cPathImp + ::cArqImp)
		Alert("O arquivo "+::cPathImp + ::cArqImp+" não foi encontrado!")      
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
   
	//apaga macro da pasta temporária se existir
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
	//sai do arquivo e destrói o objeto
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
    
	//se já preencheu, só retorna
	if len(::aDados) > 0
		return ::aDados
	endif
	
	if empty(::cArqCSV)
		Alert("Faça a importação primeiro do arquivo. Função Import()")
		return ::aDados
	endif

	//abre o arquivo csv gerado na temp
	nHandle := Ft_Fuse(::cArqCSV)
	If nHandle == -1
	   Return ::aDados
	EndIf
	
	Ft_FGoTop()

	//Pula as linhas de cabeçalho
	While nLinCab > 0 .AND. !Ft_FEof()
	   Ft_FSkip()
	   nLinCab--
	EndDo
	
	//percorre todas linhas do arquivo csv
	While !Ft_FEof()

	   //le a linha
	   cLinha := Ft_FReadLn()
	   aLinha := {}
	   
	   //verifica se a linha está em branco, se estiver pula
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
	   
	   //passa para a próxima linha
	   FT_FSkip()
	EndDo
	
	//libera o arquivo CSV
	FT_FUse()  
	
Return ::aDados

//---------------------------------------------------------------
//exclui arquivos temporários que foram gerados.
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
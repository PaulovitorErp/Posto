#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE043
Tela para multiselecao de Produtos. Chamada pelo campo A1_XRESTPR
@author Totvs TBC
@since 18/07/2014
@version 1.0

@type function
/*/
User Function TRETE043()

Local nI
Local cQry			:= ""
Local aColunas 		:= StrTokArr("B1_COD,B1_DESC",",")
Local aInf			:= {}
Local aDados		:= {}        

Local aCampos		:= {{"OK","C",002,0},{"COL1","C",TamSX3(aColunas[1])[1],0},{"COL2","C",TamSX3(aColunas[2])[1],0}} 
Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Descrição",""}} 

Local nPosIt		:= 0

Local _cAlias		:= "SB1"
Local _cColOrd		:= "B1_COD"

Private cRet		:= ""
Private cArqTrab	:= CriaTrab(aCampos) // Criando arquivo temporario

Private oDlg
Private oMark     
Private cMarca	 	:= "mk"
Private lImpFechar	:= .F.

Private oSay1, oSay2, oSay3, oSay4
Private oTexto
Private cTexto		:= Space(40)
Private nCont		:= 0   

Private cInf 		:= ""

If Alltrim(ReadVar()) == "M->A1_XRESTPR"
	
	CursorWait()

	aInf := IIF(!Empty(M->A1_XRESTPR),StrTokArr(AllTrim(M->A1_XRESTPR),"/"),{})
	cInf := M->A1_XRESTPR

	#IFDEF TOP
	If (TcSrvType()!="AS/400")

		If Select("QRYAUX") > 0
			QRYAUX->(DbCloseArea())
		Endif
		
		cQry := "SELECT B1_COD, B1_DESC"
		cQry += " FROM "+RetSqlName(_cAlias)+""
		cQry += " WHERE D_E_L_E_T_	<> '*'"
		cQry += " AND "+IIF(SubStr(_cAlias,1,1) == "S",SubStr(_cAlias,2,2),_cAlias)+"_FILIAL = '"+xFilial(_cAlias)+"'"
		cQry += " AND B1_MSBLQL <> '1'" //Não bloqueado
		cQry += " ORDER BY "+_cColOrd+""
		
		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYAUX"
		
		While QRYAUX->(!EOF())
			aAdd(aDados,{&("QRYAUX->"+aColunas[1]),&("QRYAUX->"+aColunas[2])})
		
			QRYAUX->(dbSkip())	
		EndDo                
		
		If Select("QRYAUX") > 0
			QRYAUX->(DbCloseArea())
		Endif
	Else
	#ENDIF
		DbSelectArea("SB1")			
		SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
		SB1->(DbGoTop())
		
		Do While SB1->(!EOF()) .And. SB1->B1_FILIAL == xFilial(_cAlias)
			
			AAdd(aDados,{SB1->B1_COD,SB1->B1_DESC})
			
			SB1->(DbSkip())
		EndDo		
	#IFDEF TOP
	EndIf
	#ENDIF
	
	DBUseArea(.T.,,cArqTrab,"TRBAUX",If(.F. .OR. .F., !.F., NIL), .F.)  // Criando Alias para o arquivo temporario
	
	DbSelectArea("TRBAUX")
	
	If Len(aDados) > 0
		For nI := 1 to Len(aDados)
			TRBAUX->(RecLock("TRBAUX",.T.))
			If Len(aInf) > 0 
				nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
				If nPosIt > 0
					TRBAUX->OK := "mk"                          
					nCont++
				Else
					TRBAUX->OK := "  "
				Endif                       
			Else
				TRBAUX->OK := "  "
			Endif
			TRBAUX->COL1 := aDados[nI][1]
			TRBAUX->COL2 := aDados[nI][2]
			TRBAUX->(MsUnlock())
		Next                     
	Else
		TRBAUX->(RecLock("TRBAUX",.T.))
		TRBAUX->OK		:= "  "
		TRBAUX->COL1	:= Space(6)
		TRBAUX->COL2 	:= Space(40)
		TRBAUX->(MsUnlock())
	Endif
	
	TRBAUX->(DbGoTop())
	
	CursorArrow()
	
	DEFINE MSDIALOG oDlg TITLE "Seleção de Dados - Produtos" From 000,000 TO 450,700 COLORS 0, 16777215 PIXEL
	
	@ 005, 005 SAY oSay1 PROMPT "Descrição:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 004, 050 MSGET oTexto VAR cTexto SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL Picture "@!"
	@ 005, 272 BUTTON oButton1 PROMPT "Localizar" SIZE 040, 010 OF oDlg ACTION Localiza(cTexto) PIXEL  
	
	//Browse
	oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{020,005,190,348})
	oMark:bMark 				:= {||MarcaIt()}
	oMark:oBrowse:LCANALLMARK 	:= .T.
	oMark:oBrowse:LHASMARK    	:= .T.
	oMark:oBrowse:bAllMark 		:= {||MarcaT()}
	
	@ 193, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 193, 090 SAY oSay3 PROMPT cValToChar(nCont) SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
	
	//Linha horizontal
	@ 203, 005 SAY oSay4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL
	
	@ 213, 272 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 010 OF oDlg ACTION Conf001(1) PIXEL  
	@ 213, 317 BUTTON oButton3 PROMPT "Fechar" SIZE 030, 010 OF oDlg ACTION Fech001() PIXEL    
	
	ACTIVATE MSDIALOG oDlg CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]
Endif

Return .T.                    

/*****************************/
Static Function Conf001(_nOri)
/*****************************/       

Local lAux 	:= .F.  
Local nAux	:= 0           
Local oView 	 := FWViewActive()

TRBAUX->(dbGoTop())

While TRBAUX->(!EOF())
	If TRBAUX->OK == "mk"        
		If !lAux
			M->A1_XRESTPR := AllTrim(TRBAUX->COL1)
			lAux := .T.
		Else                             
			M->A1_XRESTPR += "/" + AllTrim(TRBAUX->COL1)
		Endif    
		nAux += Len(TRBAUX->COL1)                        
	Endif                                
	
	TRBAUX->(dbSkip())      
EndDo      

If nAux == 0
	M->A1_XRESTPR := ""
Endif

FWFldPut("A1_XRESTPR", M->A1_XRESTPR)
oView:Refresh()

Fech001()

Return

/************************/
Static Function Fech001()
/************************/

lImpFechar := .T.           

If Select("TRBAUX") > 0
	TRBAUX->(DbCloseArea()) 
Endif	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Apagando arquivo temporario                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

FErase(cArqTrab + GetDBExtension())
FErase(cArqTrab + OrdBagExt())          

oDlg:End()

Return

/************************/
Static Function MarcaIt()
/************************/

If TRBAUX->OK == "mk"
	nCont++
Else
	--nCont
Endif

oSay3:Refresh()

Return

/************************/
Static Function MarcaT()
/************************/

Local lMarca 	:= .F.
Local lNMARCA 	:= .F. 

nCont := 0

TRBAUX->(dbGoTop())      

While TRBAUX->(!EOF())
	If TRBAUX->OK == "mk" .And. !lMarca
		RecLock("TRBAUX",.F.)
		TRBAUX->OK := "  "
		TRBAUX->(MsUnlock())
		lNMarca := .T.
	Else  
		If !lNMarca	
			RecLock("TRBAUX",.F.)
			TRBAUX->OK := "mk"
			TRBAUX->(MsUnlock())
			nCont++                     
			lMarca := .T.
		Endif
	Endif
	
    TRBAUX->(dbSkip())
EndDo

TRBAUX->(dbGoTop())

oSay3:Refresh()

Return

/********************************/
Static Function Localiza(_cTexto)
/********************************/   

If !Empty(_cTexto)
	TRBAUX->(dbSkip())

	While TRBAUX->(!EOF())
		If AllTrim(_cTexto) $ TRBAUX->COL2
			Exit	
		Endif
			
		TRBAUX->(dbSkip())
	EndDo
Else
	TRBAUX->(dbGoTop())
Endif

Return

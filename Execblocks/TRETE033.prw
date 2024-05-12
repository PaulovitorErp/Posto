#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE033
Estorno NF-e de acobertadmento
@author TOTVS
@since 06/06/2019
@version P11
@param nulo
@return nulo

Quando for necessário ou a operação do cliente necessitar gerar uma nota para múltiplos cupons, 
será necessário criar o parâmetro MV_LJ130MN

/*/

/***********************/
User Function TRETE033()
/***********************/ 

Local cTitulo 		:= "Estorno NF s/ CF"
Local aButtons 		:= {} 
Local aDadosNF		:= {} 

Private cPerg 		:= "ESTNFCF"
Private oGet1             

Private oSay1
Private oButton1, oButton2

Private nAux		:= 0
Private nCont		:= 0

Private nColOrder	:= 0  

Private __XVEZ 		:= "0"

Private lNfAcobert	:= SuperGetMv("MV_XNFACOB",.F.,.F.)

Static oDlgEstNfe  

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !DtMovFin()
	Return
Endif

If !ValidPerg()  
	Return
Endif 

cMV_PAR01 := MV_PAR01
dMV_PAR02 := MV_PAR02
dMV_PAR03 := MV_PAR03
cMV_PAR04 := MV_PAR04
cMV_PAR05 := MV_PAR05
cMV_PAR06 := MV_PAR06
cMV_PAR07 := MV_PAR07
cMV_PAR08 := MV_PAR08  
cMV_PAR09 := MV_PAR09  
cMV_PAR10 := MV_PAR10  
cMV_PAR11 := MV_PAR11

aObjects := {}
aSizeAut := MsAdvSize()

//Largura, Altura, Modifica largura, Modifica altura
aAdd(aObjects,{100, 90, .T., .T.}) //Browse
aAdd(aObjects,{100, 10, .T., .T.}) //Rodapé

aInfo 	:= {aSizeAut[1],aSizeAut[2],aSizeAut[3],aSizeAut[4],2,2}
aPosObj := MsObjSize(aInfo,aObjects,.T.)

if !BuscaDados(@aDadosNF)
	Return
endif

DEFINE MSDIALOG oDlgEstNfe TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

//Browse
oGet1 := GetDados1()
oGet1:aCols := aDadosNF
oGet1:oBrowse:bHeaderClick := {|oBrw,nCol| IIF(nCol == 1,(CliqueT(),oBrw:SetFocus()),),(,nColOrder := nCol)}
bSvblDblClick := oGet1:oBrowse:bLDblClick
oGet1:oBrowse:bLDblClick := {|| IIF(oGet1:oBrowse:nColPos <> 1,GdRstDblClick(@oGet1,@bSvblDblClick),Clique())}

//Linha horizontal
If '12' $ cVersao
	@ aPosObj[2,1] - 5, aPosObj[2,2] SAY oSay1 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgEstNfe COLORS CLR_GRAY, 16777215 PIXEL
	
	@ aPosObj[2,1] + 5, aPosObj[1,4] - 90 BUTTON oButton1 PROMPT "Processar" SIZE 040, 010 OF oDlgEstNfe ACTION EstNf()  PIXEL  
	@ aPosObj[2,1] + 5, aPosObj[1,4] - 40 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgEstNfe ACTION oDlgEstNfe:End() PIXEL  
Else
	@ aPosObj[2,1] + 10, aPosObj[2,2] SAY oSay1 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgEstNfe COLORS CLR_GRAY, 16777215 PIXEL
	
	@ aPosObj[2,1] + 20, aPosObj[1,4] - 90 BUTTON oButton1 PROMPT "Processar" SIZE 040, 010 OF oDlgEstNfe ACTION EstNf()  PIXEL  
	@ aPosObj[2,1] + 20, aPosObj[1,4] - 40 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgEstNfe ACTION oDlgEstNfe:End() PIXEL  
Endif

ACTIVATE MSDIALOG oDlgEstNfe CENTERED 

Return .T.

/**************************/
Static Function GetDados1()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"OK","F2_FILIAL","F2_DOC","F2_SERIE","F2_CLIENTE","F2_LOJA","A1_NOME","F2_COND","F2_EMISSAO","F2_VALBRUT","RECNO"}
Local aAlterFields 	:= {}

//Define field properties
For nX := 1 to Len(aFields)		
	If aFields[nX] == "OK" //Checkbox
	  	Aadd(aHeaderEx, {"","OK","@BMP",2,0,"","€€€€€€€€€€€€€€","C","","","",""})
	ElseIf aFields[nX] == "RECNO" 
		Aadd(aHeaderEx, {"R_E_C_N_O_","RECNO","@!",6,,"","€€€€€€€€€€€€€€","C","","","",""})		
	ElseIf !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Endif
Next 

For nX := 1 To Len(aFields)
	If  !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Else
		Do Case
			Case aFields[nX] == "OK"
				Aadd(aFieldFill, "LBNO")

			Case aFields[nX] == "RECNO"
				Aadd(aFieldFill, Space(6))
		EndCase
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

If '12' $ cVersao

	Return MsNewGetDados():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
			"AllwaysTrue","","AllwaysTrue",oDlgEstNfe,aHeaderEx,aColsEx) 
Else
	Return MsNewGetDados():New(aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
			"AllwaysTrue","","AllwaysTrue",oDlgEstNfe,aHeaderEx,aColsEx) 
Endif

/***************************/
Static Function BuscaDados(aDadosNF)
/***************************/

Local cQry 		:= "" 
Local lRet		:= .F.
Local cEspecie	:= ""
Local cCliSF2	:= ""
Local cLjSF2	:= "" 
Local dDtDigit	:= CToD("")  
Local nMvSpedExc := SuperGetMV("MV_SPEDEXC",,24) //Indica a quantidade de horas que a NF ainda pode ser cancelada.

//Limpa o aCols
aSize(aDadosNF,0)

If Select("QRYNFCF") > 0
	QRYNFCF->(DbCloseArea())
Endif

cQry := "SELECT SF2.F2_FILIAL,"
cQry += " SF2.F2_DOC,"
cQry += " SF2.F2_SERIE,"
cQry += " SF2.F2_CLIENTE,"
cQry += " SF2.F2_LOJA,"
cQry += " SA1.A1_NOME,"
cQry += " SF2.F2_COND,"
cQry += " SF2.F2_EMISSAO,"
cQry += " SF2.F2_VALBRUT,"
cQry += " SF2.R_E_C_N_O_ AS RECNO"
cQry += " FROM "+RetSqlName("SF2")+" SF2, "+RetSqlName("SA1")+" SA1"
cQry += " WHERE SF2.D_E_L_E_T_	= ' '"
cQry += " AND SA1.D_E_L_E_T_	= ' '"

If Empty(cMV_PAR01)
	cQry += " AND SF2.F2_FILIAL		= '"+xFilial("SE1")+"'"
	cQry += " AND SA1.A1_FILIAL		= '"+xFilial("SA1")+"'"
Else
	cQry += " AND SF2.F2_FILIAL		= '"+cMV_PAR01+"'"
	cQry += " AND SA1.A1_FILIAL		= '"+xFilial("SA1",cMV_PAR01)+"'"
Endif

cQry += " AND SF2.F2_CLIENTE	= SA1.A1_COD"
cQry += " AND SF2.F2_LOJA		= SA1.A1_LOJA"    
cQry += " AND SF2.F2_NFCUPOM	<> ' '"
cQry += " AND SF2.F2_ESPECIE	<> 'CF'"
If lNfAcobert
	cQry += " AND SF2.F2_ESPECIE	<> 'NFCE'"
Endif
cQry += " AND SF2.F2_EMISSAO	BETWEEN '"+DToS(dMV_PAR02)+"' AND '"+DToS(dMV_PAR03)+"'"
cQry += " AND SF2.F2_DOC		BETWEEN '"+cMV_PAR04+"' AND '"+cMV_PAR06+"'"
cQry += " AND SF2.F2_SERIE		BETWEEN '"+cMV_PAR05+"' AND '"+cMV_PAR07+"'"
cQry += " AND SF2.F2_CLIENTE	BETWEEN '"+cMV_PAR08+"' AND '"+cMV_PAR10+"'"
cQry += " AND SF2.F2_LOJA		BETWEEN '"+cMV_PAR09+"' AND '"+cMV_PAR11+"'"
cQry += " ORDER BY 1,2,3"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\ESTNFE.txt",cQry)
TcQuery cQry NEW Alias "QRYNFCF"

If QRYNFCF->(!EOF())

	DbSelectArea("SF2")                         
	SF2->(DbSetOrder(1))

	While QRYNFCF->(!EOF()) 

		SF2->(DbGoTo(QRYNFCF->RECNO))
			
		cEspecie := SF2->F2_ESPECIE 
		cCliSF2  := SF2->F2_CLIENTE
		cLjSF2   := SF2->F2_LOJA

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ 	
		//³ Verifica a quantidade de horas indicada no parametro MV_SPEDEXC e valida se a NF pode ser excluida³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If SF2->(FieldPos("F2_DAUTNFE")) > 0 .And. !Empty(SF2->F2_DAUTNFE)
			dDtDigit := SF2->F2_DAUTNFE
		ElseIf SF2->(FieldPos('F2_DTDIGIT')) > 0 .And. !Empty(SF2->F2_DTDIGIT)
			dDtDigit := SF2->F2_DTDIGIT
		Else
			dDtDigit := SF2->F2_EMISSAO
		EndIf 
		
		nQtdHoras := SubtHoras(dDtDigit,IIF( SF2->(FieldPos("F2_HAUTNFE")) > 0 .And. !Empty(SF2->F2_HAUTNFE),SF2->F2_HAUTNFE,SF2->F2_HORA),dDataBase, SubStr(Time(),1,2)+":"+SubStr(Time(),4,2))

		If "SPED"$cEspecie .And. (SF2->F2_FIMP$"TS") // Verifica apenas a especie como SPED e notas que foram transmitidas ou impresso o DANFE

			If nQtdHoras > nMvSpedExc
				QRYNFCF->(DbSkip())
    			Loop		
    		EndIf
    	Endif

		aAdd(aDadosNF,{"LBNO",;
						  QRYNFCF->F2_FILIAL,;
						  QRYNFCF->F2_DOC,;
						  QRYNFCF->F2_SERIE,;
						  QRYNFCF->F2_CLIENTE,;
						  QRYNFCF->F2_LOJA,;
						  QRYNFCF->A1_NOME,;
						  QRYNFCF->F2_COND,;
						  DToC(SToD(QRYNFCF->F2_EMISSAO)),;
						  QRYNFCF->F2_VALBRUT,;
						  QRYNFCF->RECNO,;						  
						  .F.})

		lRet := .T.	
				
		QRYNFCF->(DbSkip())
	EndDo
	
Endif  

if empty(aDadosNF)
	MsgInfo("Não há notas fiscais encontradas com os filtros informados.","Atenção")
endif

If Select("QRYNFCF") > 0
	QRYNFCF->(DbCloseArea())
Endif

Return lRet

/***********************/
Static Function Clique()
/***********************/

If oGet1:aCols[oGet1:nAt][1] == "LBOK"
	oGet1:aCols[oGet1:nAt][1] := "LBNO"
Else
	oGet1:aCols[oGet1:nAt][1] := "LBOK"	
Endif

oGet1:oBrowse:Refresh()

Return 

/************************/
Static Function CliqueT()
/************************/
Local nI

If nAux == 1
	nAux := 0
Else

	If oGet1:aCols[1][1] == "LBOK"
		For nI := 1 To Len(oGet1:aCols)
			oGet1:aCols[nI][1] := "LBNO"
		Next
	Else
		For nI := 1 To Len(oGet1:aCols)
			oGet1:aCols[nI][1] := "LBOK"
		Next
	Endif
	
	nAux := 1
Endif                 

oGet1:oBrowse:Refresh()   

Return                    

/**********************/
Static Function EstNf()
/**********************/
                              
Local nI
Local aNFS			:= {} //Array com as notas fiscal para estorno 
Local lNota			:= .F. //Informa se eh geracao ou estorno da nota

Local cAuxCli		:= ""
Local cAuxLoja		:= ""

Private lMsHelpAuto := .T. // Variavel de controle interno do ExecAuto
Private lMsErroAuto := .F. // Variavel que informa a ocorrência de erros no ExecAuto

For nI := 1 To Len(oGet1:aCols)

	If oGet1:aCols[nI][1] == "LBOK"
		
		If Empty(cAuxCli)
	
			cAuxCli 	:= oGet1:aCols[nI][5] 
			cAuxLoja 	:= oGet1:aCols[nI][6] 
		Else 
			If cAuxCli <> oGet1:aCols[nI][5] .Or. cAuxLoja <> oGet1:aCols[nI][6] 
				MsgInfo("Havendo seleção de mais de uma Nota Fiscal, obrigatoriamente estas deverão pertencer ao mesmo Cliente e Loja!!","Atenção")
				Return
			Endif
		Endif
	Endif
Next

For nI := 1 To Len(oGet1:aCols)
	If oGet1:aCols[nI][1] == "LBOK" .AND. !empty(oGet1:aCols[nI][3])

		SF2->(DbSetOrder(1))//"F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO"
		If SF2->( DbSeek(xFilial("SF2") + oGet1:aCols[nI][3] + oGet1:aCols[nI][4]) )
			
			if !U_TR042VLP() //valida o prazo para cancelamento
				Return
			endif

			AAdd(aNFS,{oGet1:aCols[nI][3],oGet1:aCols[nI][4],oGet1:aCols[nI][5],oGet1:aCols[nI][6]}) //Documento,Serie,Cliente e Loja
		Else
			MsgInfo("Nota fiscal "+oGet1:aCols[nI][3]+"/"+oGet1:aCols[nI][4]+" não encontrada para estorno!","Atenção")
			Return
		Endif
				
	Endif
Next

If Len(aNFS) == 0
	MsgInfo("Nenhum registro selecionado!!","Atenção")	
	Return
Else
	
	If MsgYesNo("Haverá o estorno dos registros selecionados, deseja continuar?")

		//Chamada da EXECAUTO
		LojR130(aNFS,lNota,cAuxCli,cAuxLoja)
		
		If lMsErroAuto
			MostraErro() 
			//DisarmTransaction()
			//Libera sequencial
			//RollBackSx8()
		Else
			MsgInfo("Estorno processado com sucesso!!","Atenção")
			oDlgEstNfe:End()
		EndIf
	Endif
Endif

Return

/**************************/
Static Function ValidPerg() 
/**************************/

Local aHelpPor := {}

U_uPutSx1(cPerg,"01","Filial			?","","","mv_ch1","C",len(cFilAnt),0,0,"G","","SM0","","","mv_par01","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"02","Emissao de 		?","","","mv_ch2","D",8,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"03","Emissao ate		?","","","mv_ch3","D",8,0,0,"G","","","","","mv_par03","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"04","Documento de		?","","","mv_ch4","C",9,0,0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"05","Serie de			?","","","mv_ch5","C",3,0,0,"G","","","","","mv_par05","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"06","Documento ate	?","","","mv_ch6","C",9,0,0,"G","","","","","mv_par06","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"07","Serie ate		?","","","mv_ch7","C",3,0,0,"G","","","","","mv_par07","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"08","Cliente de       ?","","","mv_ch8","C",6,0,0,"G","","SA1","","","mv_par08","","","","      ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"09","Loja de          ?","","","mv_ch9","C",2,0,0,"G","","","","","mv_par09","","","","  ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"10","Cliente ate      ?","","","mv_ch10","C",6,0,0,"G","","SA1","","","mv_par10","","","","ZZZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uPutSx1(cPerg,"11","Loja ate         ?","","","mv_ch11","C",2,0,0,"G","","","","","mv_par11","","","","ZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})

Return Pergunte(cPerg,.T.)  

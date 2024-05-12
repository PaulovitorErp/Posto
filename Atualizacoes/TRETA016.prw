#include "totvs.ch"
#include "topconn.ch"
#include "FWPrintSetup.ch"
#include "RPTDEF.CH"

/*/{Protheus.doc} TRETA016
Funções NF-e e NFC-e

@author TOTVS
@since 02/11/2017
@version P11
@param Nao recebe parametros
@return nulo
/*/
User Function TRETA016()

	Local cTitulo 		:= "Funções NF-e e NFC-e"
	Local aLarg			:= {20,20,20,40,30,40,30,140,60,60,40,40,40,140,60}
	Local aCabec2		:= {"Produto","Descricao","Un","Qtde.","Vlr. unit.","Total Bruto","Desconto (R$)","Total Liq."}
	Local aLarg2		:= {40,140,30,60,60,60,60,60}
	Local oBmp1

	Private oDlgNf
	Private aCabec		:= {"","","","Documento","Serie","Cliente","Loja","Nome","CGC/CPF","Valor","Emissao","Placa","Tipo","Descricao","R_E_C_N_O_"}

	Private oFldDoc
	Private oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12, oSay13, oSay14, oSay15, oSay16, oSay17, oSay18, oSay19
	Private oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet10, oGet11, oGet12

	Private cGet1 		:= Space(14)
	Private cGet2		:= Space(200)
	Private cGet3		:= Space(200)
	Private cGet4		:= Space(200)
	Private dGet5		:= CToD("")
	Private dGet6		:= CToD("")
	Private cGet7		:= Space(9)
	Private cGet8		:= Space(9)
	Private cGet9 		:= Space(8)
	Private nGet10 		:= 0
	Private nGet11		:= 0
	Private cGet12		:= Space(3)

	Private oDoc
	Private lCheckBox1	:= .T.
	Private lCheckBox2	:= .T.
	Private lCheckBox3	:= .F.

	Private cCbSitDoc	:= "000-Sem Filtro"
	Private aCbSitDoc	:= {"000-Sem Filtro","100-Autorizadas","101-Cancelada","102-Inutilizada","110-Denegada"}

	Private oButton1, oButton2, oButton3, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9, oButton10, oButton11, oBtnFechar

	Private oMark		:= LoadBitmap(GetResources(),"LBOK")
	Private oNoMark		:= LoadBitmap(GetResources(),"LBNO")

	Private oLegDoc
	Private oBranco		:= LoadBitmap(GetResources(),"BR_BRANCO")
	Private oLaranja	:= LoadBitmap(GetResources(),"BR_LARANJA")
	Private oAmarelo	:= LoadBitmap(GetResources(),"BR_AMARELO")

	Private oLegStatus
	Private oVerde		:= LoadBitmap(GetResources(),"BR_VERDE")
	Private oVermelho	:= LoadBitmap(GetResources(),"BR_VERMELHO")
	Private oAzul		:= LoadBitmap(GetResources(),"BR_AZUL")
	Private oPreto		:= LoadBitmap(GetResources(),"BR_PRETO")
	Private oCinza		:= LoadBitmap(GetResources(),"BR_CINZA")
	Private oMarrom		:= LoadBitmap(GetResources(),"BR_MARRROM")

	Private aReg		:= {{.F.,oBranco,oBranco,Space(9),Space(3),Space(6),Space(2),Space(40),Space(14),0,CToD(""),Space(8),Space(3),Space(40),Space(9)}}
	Private aReg2		:= {{Space(15),Space(30),Space(2),0,0,0,0,0}}

	Private nCont := nTot := 0

	Private lFiltro		:= .F.

	Private nColOrder	:= 0
	Private cTpTit		:= ""

	Private cIdEnt		:= ""
	Private cAmbiente	:= ""
	Private cModalidade	:= ""

	aObjects := {}
	aSizeAut := MsAdvSize()

	//Largura, Altura, Modifica largura, Modifica altura
	aAdd(aObjects, {100, 090, .T., .T.}) //Folder
	aAdd(aObjects, {100, 005, .T., .F.}) //Linha horizontal
	aAdd(aObjects, {100, 005, .F., .F.}) //Botao

	aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects, .T. )

	//DEFINE MSDIALOG oDlgNf TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] /*OF oMainWnd*/ PIXEL
	oDlgNf := MSDialog():New(aSizeAut[7],0,aSizeAut[6],aSizeAut[5],cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)

	//Folder
	@ aPosObj[1,1] - 30, aPosObj[1,2] FOLDER oFldDoc SIZE aPosObj[1,4], aPosObj[1,3] - 10 OF oDlgNf ITEMS "Filtro","Documentos" COLORS 0, 16777215 PIXEL
	oFldDoc:nOption := 1
	oFldDoc:bChange := {|| HabBotoes()}

	//Pasta Filtro
	@ 005, 005 SAY oSay1 PROMPT "CGC/CPF ?" SIZE 030, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 004, 080 MSGET oGet1 VAR cGet1 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SA1NFE"

	@ 018, 005 SAY oSay2 PROMPT "Cliente ?" SIZE 030, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 017, 080 GET oGet2 VAR cGet2 MEMO SIZE 100, 040 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL;
		VALID {||cGet2 := AllTrim(cGet2),cGet2 := Upper(cGet2),.T.} // Adicionado: Felipe Sousa - 16/01/2024 CHAMADO: POSTO-284
	@ 017, 187 BUTTON oButton1 PROMPT "Buscar" SIZE 040, 010 OF oFldDoc:aDialogs[1] ACTION FilCli() PIXEL
	@ 032, 187 BUTTON oButton2 PROMPT "Limpar" SIZE 040, 010 OF oFldDoc:aDialogs[1] ACTION LimpMemo(@oGet2,@cGet2) PIXEL
	//oGet2:lReadOnly := .T. // Comentado por: Felipe Sousa - 16/01/2024 CHAMADO: POSTO-284

	@ 060, 005 SAY oSay3 PROMPT "Forma de Pagamento ?" SIZE 060, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 059, 080 GET oGet3 VAR cGet3 MEMO SIZE 100, 040 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 059, 187 BUTTON oButton3 PROMPT "Buscar" SIZE 040, 010 OF oFldDoc:aDialogs[1] ACTION FilFormaPg() PIXEL
	@ 074, 187 BUTTON oButton4 PROMPT "Limpar" SIZE 040, 010 OF oFldDoc:aDialogs[1] ACTION LimpMemo(@oGet3,@cGet3) PIXEL
	oGet3:lReadOnly := .T.

	@ 102, 005 SAY oSay4 PROMPT "Produto ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 101, 080 GET oGet4 VAR cGet4 MEMO SIZE 100, 040 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 101, 187 BUTTON oButton5 PROMPT "Buscar" SIZE 040, 010 OF oFldDoc:aDialogs[1] ACTION FilProd() PIXEL
	@ 116, 187 BUTTON oButton6 PROMPT "Limpar" SIZE 040, 010 OF oFldDoc:aDialogs[1] ACTION LimpMemo(@oGet4,@cGet4) PIXEL
	@ 131, 187 CHECKBOX oCheckBox3 VAR lCheckBox3 PROMPT "Somente produtos selecionados"  Size 120, 007 PIXEL OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	oGet4:lReadOnly := .T.

	@ 143, 005 SAY oSay5 PROMPT "Emissão de ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 142, 080 MSGET oGet5 VAR dGet5 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 156, 005 SAY oSay6 PROMPT "Emissão ate ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 155, 080 MSGET oGet6 VAR dGet6 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 169, 005 SAY oSay7 PROMPT "Placa ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 168, 080 MSGET oGet9 VAR cGet9 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "DA3" PICTURE "@!R NNN-9N99"

	@ 182, 005 SAY oSay8 PROMPT "Valor de ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 181, 080 MSGET oGet10 VAR nGet10 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL  PICTURE "@E 999,999,999.99"

	@ 195, 005 SAY oSay9 PROMPT "Valor ate ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 194, 080 MSGET oGet11 VAR nGet11 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL  PICTURE "@E 999,999,999.99"

	@ 208, 005 SAY oSay7 PROMPT "Documento de ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 207, 080 MSGET oGet7 VAR cGet7 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SF2"

	@ 221, 005 SAY oSay8 PROMPT "Documento ate ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 220, 080 MSGET oGet8 VAR cGet8 SIZE 060, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SF2"

	@ 234, 005 SAY oSay19 PROMPT "Adm. Financeira ?" SIZE 040, 007 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 233, 080 MSGET oGet12 VAR cGet12 SIZE 030, 010 OF oFldDoc:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SAE"

	@ 005, 325 GROUP oDoc TO 030, 445 PROMPT "Tipo Documento" OF oFldDoc:aDialogs[1] COLOR 0, 16777215 PIXEL
	@ 017, 335 CHECKBOX oCheckBox1 VAR lCheckBox1 PROMPT "NF-e"  Size 070, 007 PIXEL OF oDoc COLORS 0, 16777215 PIXEL
	@ 017, 390 CHECKBOX oCheckBox2 VAR lCheckBox2 PROMPT "NFC-e"  Size 070, 007 PIXEL OF oDoc COLORS 0, 16777215 PIXEL

	@ 035,325 SAY "Situação Doc. ?" Size 050,007 COLOR CLR_BLACK PIXEL OF oFldDoc:aDialogs[1]
	@ 034,373 ComboBox cCbSitDoc Items aCbSitDoc Size 072,010 PIXEL OF oFldDoc:aDialogs[1]

	//Pasta Cupons Fiscais
	//Browse Cabeçalho
	oBrw := TWBrowse():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,4] - 10,aPosObj[1,3] - 165,,aCabec,aLarg,oFldDoc:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	oBrw:SetArray(aReg)
	oBrw:bChange 		:= {|| BuscaItens()}
	oBrw:blDblClick 	:= {|| MarkReg()}
	oBrw:bHeaderClick 	:= {|oObj,nCol| IIF(nCol ==1 ,MarkAllReg(),),(OrderGrid(oBrw,nCol), nColOrder := nCol)}
	oBrw:bLine 			:= {|| {IIF(aReg[oBrw:nAT][1],oMark,oNoMark),aReg[oBrw:nAT][2],aReg[oBrw:nAT][3],aReg[oBrw:nAT][4],aReg[oBrw:nAT][5],;
								aReg[oBrw:nAT][6],aReg[oBrw:nAT][7],aReg[oBrw:nAT][8],aReg[oBrw:nAT][9],aReg[oBrw:nAT][10],aReg[oBrw:nAT][11],;
								aReg[oBrw:nAT][12],aReg[oBrw:nAT][13],aReg[oBrw:nAT][14],aReg[oBrw:nAT][15]}}

	@ (aPosObj[1,3] - 160) + 05 /*aPosObj[1,1] + 113*/, aPosObj[1,2] SAY oSay23 PROMPT "Itens" SIZE 040, 007 OF oFldDoc:aDialogs[2] COLORS CLR_BLUE, 16777215 PIXEL

	//Browse Itens
	oBrw2 := TWBrowse():New(  ( (aPosObj[1,3] - 165) + 15 ) + 05 /*aPosObj[1,1] + 125*/,aPosObj[1,2],aPosObj[1,4] - 10, ( aPosObj[1,3] - ( aPosObj[2,1] - 51) ) + 30  /*aPosObj[1,3] - 170*/,,aCabec2,aLarg2,oFldDoc:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	oBrw2:SetArray(aReg2)
	oBrw2:bLine := {|| {aReg2[oBrw2:nAT][1],aReg2[oBrw2:nAT][2],aReg2[oBrw2:nAT][3],aReg2[oBrw2:nAT][4],aReg2[oBrw2:nAT][5],;
						aReg2[oBrw2:nAT][6],aReg2[oBrw2:nAT][7],aReg2[oBrw2:nAT][8]}}

	@ aPosObj[3,1] - 10, aPosObj[3,2] BUTTON oButton7 PROMPT "Visualizar Doc." SIZE 050, 010 OF oDlgNf ACTION {|| MsgRun("Visualizando documento...","Aguarde",{|| VisDoc()})} PIXEL
	@ aPosObj[3,1] - 10, aPosObj[3,2] + 60 BUTTON oButton8 PROMPT "Exportar XML" SIZE 050, 010 OF oDlgNf ACTION {|| ExpXML()} PIXEL
	@ aPosObj[3,1] - 10, aPosObj[3,2] + 120 BUTTON oButton9 PROMPT "Imprimir PDF" SIZE 050, 010 OF oDlgNf ACTION {|| ImpDoc()} PIXEL

	//Contador e Totalizador
	@ aPosObj[2,1] - 62, aPosObj[2,2] SAY oSay11 PROMPT "Registros selecionados:" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ aPosObj[2,1] - 62, aPosObj[2,2] + 70 SAY oSay12 PROMPT cValToChar(nCont) SIZE 040, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 62, aPosObj[2,2] + 90 SAY oSay13 PROMPT ", totalizando R$" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ aPosObj[2,1] - 62, aPosObj[2,2] + 130 SAY oSay14 PROMPT nTot SIZE 060, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

	//Legenda NFC-e NFC-e
	@ aPosObj[2,1] - 53, aPosObj[2,2] SAY oSay15 PROMPT "Legenda Tipo Documento:" SIZE 120, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 52, aPosObj[2,2] + 75 BITMAP oBmp1 ResName "BR_LARANJA" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 52, aPosObj[2,2] + 090 SAY oSay16 PROMPT "NF-e" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 52, aPosObj[2,2] + 155 BITMAP oBmp3 ResName "BR_AMARELO" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 52, aPosObj[2,2] + 170 SAY oSay17 PROMPT "NFC-e" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	//Legenda Status do Documento
	@ aPosObj[2,1] - 43, aPosObj[2,2] SAY oSay15 PROMPT "Legenda Status Documento:" SIZE 120, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 75 BITMAP oBmp1 ResName "BR_VERDE" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 42, aPosObj[2,2] + 090 SAY oSay16 PROMPT "Autorizadas" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 155 BITMAP oBmp3 ResName "BR_AZUL" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 42, aPosObj[2,2] + 170 SAY oSay17 PROMPT "Canceladas" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 235 BITMAP oBmp3 ResName "BR_MARROM" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 42, aPosObj[2,2] + 250 SAY oSay17 PROMPT "Inutilizadas" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 315 BITMAP oBmp3 ResName "BR_PRETO" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 42, aPosObj[2,2] + 330 SAY oSay17 PROMPT "Denegadas" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 395 BITMAP oBmp3 ResName "BR_BRANCO" OF oFldDoc:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 42, aPosObj[2,2] + 410 SAY oSay17 PROMPT "Status ausente" SIZE 080, 007 OF oFldDoc:aDialogs[2] COLORS 0, 16777215 PIXEL

	//Linha horizontal
	@ aPosObj[2,1] - 10, aPosObj[2,2] SAY oSay18 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgNf COLORS CLR_GRAY, 16777215 PIXEL

	@ aPosObj[3,1] - 10, aPosObj[1,4] - 110 BUTTON oButton10 PROMPT "Aplicar filtro" SIZE 060, 010 OF oDlgNf;
						ACTION {|| Processa({|| Filtro(),"Aguarde"}),lFiltro := .T.,oFldDoc:ShowPage(2)} PIXEL

	@ aPosObj[3,1] - 10, aPosObj[1,4] - 90 BUTTON oButton11 PROMPT "Filtro" SIZE 040, 010 OF oDlgNf ACTION {||oFldDoc:ShowPage(1),;
						oButton7:lVisible 	:= .F.,;
						oButton8:lVisible 	:= .F.,;
						oButton9:lVisible 	:= .F.,;
						oButton10:lVisible 	:= .T.,;
						oButton11:lVisible 	:= .F.} PIXEL

	@ aPosObj[3,1] - 10, aPosObj[1,4] - 40 BUTTON oBtnFechar PROMPT "Fechar" SIZE 040, 010 OF oDlgNf ACTION {|| fechaTela(oDlgNf) }/*oDlgNf:End()*/ PIXEL

	oButton7:lVisible 	:= .F.
	oButton8:lVisible 	:= .F.
	oButton9:lVisible 	:= .F.
	oButton10:lVisible 	:= .T.
	oButton11:lVisible 	:= .F.

	oGet1:SetFocus()

	//ACTIVATE MSDIALOG oDlgNf CENTERED
	oDlgNf:Activate(,,,.T.,{|| /*validou*/.T.},,{|| /*iniciou*/} )

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} fechaTela
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function fechaTela(oDlgNf)
	oDlgNf:End()
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} HabBotoes
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function HabBotoes()

	If oFldDoc:nOption == 1
		oFldDoc:SetOption(1)

		oButton7:lVisible 	:= .F.
		oButton8:lVisible 	:= .F.
		oButton9:lVisible 	:= .F.
		oButton10:lVisible 	:= .T.
		oButton11:lVisible 	:= .F.
	Else
		If !lFiltro
			Processa({|| Filtro(),"Aguarde"})
		Else
			lFiltro := .F.
		Endif
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Filtro
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Filtro()

	Local cQry 			:= ""

	Local cCli 			:= ""
	Local cFormaPg		:= ""
	Local cProd			:= ""
	Local aContent 		:= {} // Vetor com os dados do SX5com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO

	If !lCheckBox1 .And. !lCheckBox2
		MsgInfo("Obrigatoriamente um tipo de documento deve ser selecionado!!","Atenção")
		Return
	Endif

	nCont	:= 0
	nTot	:= 0

	aSize(aReg,0) //Limpa o array

	ProcRegua(0)
	IncProc()

	//Busca os documentos
	If Select("QRYDOC") > 0
		QRYDOC->(dbCloseArea())
	Endif

	cQry += " SELECT SF2.F2_ESPECIE,"
	cQry += " SF2.F2_DOC,"
	cQry += " SF2.F2_SERIE,"
	cQry += " SF2.F2_CLIENTE,"
	cQry += " SF2.F2_LOJA,"
	cQry += " SA1.A1_NOME,"
	cQry += " SA1.A1_CGC,"
	cQry += " SF2.F2_VALBRUT AS VLR_DOC,"
	cQry += " SF2.F2_EMISSAO,"
	cQry += " SL1.L1_PLACA,"
	cQry += " SE1.E1_TIPO,"
	cQry += " SF3.F3_CODRSEF,"
	cQry += " SF3.F3_CHVNFE,"
	cQry += " SF3.F3_DTCANC,"
	cQry += " SF2.R_E_C_N_O_ AS RECNO"
	cQry += " FROM "+RetSqlName("SF2")+" SF2"

	cQry += " 									INNER JOIN "+RetSqlName("SA1")+" SA1 	ON SF2.F2_CLIENTE	= SA1.A1_COD"
	cQry += "																			AND SF2.F2_LOJA		= SA1.A1_LOJA"
	cQry += "																			AND SA1.D_E_L_E_T_	<> '*'"
	cQry += " 																			AND SA1.A1_FILIAL	= '"+xFilial("SA1")+"'"

	cQry += " 									INNER JOIN "+RetSqlName("SF3")+" SF3 	ON SF2.F2_CLIENTE	= SF3.F3_CLIEFOR"
	cQry += " 										 									AND SF2.F2_LOJA		= SF3.F3_LOJA"
	cQry += " 										 									AND SF2.F2_DOC		= SF3.F3_NFISCAL"
	cQry += " 										 									AND SF2.F2_SERIE	= SF3.F3_SERIE"

	//Status documento
	If SubStr(cCbSitDoc,1,3) <> "000" //000-Sem Filtro
		cQry += "																		AND SF3.F3_CODRSEF	= '"+SubStr(cCbSitDoc,1,3)+"'"
	Endif

	cQry += " 																			AND SF3.F3_FILIAL	= '"+xFilial("SF3")+"'"
	cQry += "																			AND SF3.D_E_L_E_T_	<> '*'"

	// Adm. Financeira
	If !Empty(cGet12)
		cQry += " 									INNER JOIN "+RetSqlName("SE1")+" SE1 	ON SF2.F2_SERIE		= SE1.E1_PREFIXO"
		cQry += " 										 									AND SF2.F2_DOC		= SE1.E1_NUM"
		cQry += " 										 									AND SE1.E1_LOJA		= '01'"
		cQry += "																			AND SE1.D_E_L_E_T_	<> '*'"
		cQry += " 																			AND SE1.E1_FILIAL	= '"+xFilial("SE1")+"'"
		//TODO: trocar vinculo da SAE par ficar com campo E1_ADM
		cQry += " 									INNER JOIN "+RetSqlName("SAE")+" SAE 	ON SE1.E1_CLIENTE	= SAE.AE_COD"
		cQry += " 										 									AND SAE.AE_COD		= SE1.E1_CLIENTE"
		cQry += " 										 									AND SAE.AE_COD		= '"+cGet12+"'"
		cQry += "																			AND SAE.D_E_L_E_T_	<> '*'"
		cQry += " 																			AND SAE.AE_FILIAL	= '"+xFilial("SAE")+"'"
	Else
		cQry += " 									LEFT JOIN "+RetSqlName("SE1")+" SE1 	ON SF2.F2_SERIE		= SE1.E1_PREFIXO"
		cQry += " 										 									AND SF2.F2_DOC		= SE1.E1_NUM"
		cQry += "																			AND SE1.D_E_L_E_T_	<> '*'"
		cQry += " 																			AND SE1.E1_FILIAL	= '"+xFilial("SE1")+"'"
	EndIf

	cQry += " 									LEFT JOIN "+ RetSqlName("SL1") + " SL1 		ON ( "
	cQry += " 										 									SL1.L1_DOC = SF2.F2_DOC "
	cQry += " 										 									AND SL1.L1_SERIE = SF2.F2_SERIE "
	cQry += " 										 									AND SL1.L1_PDV = SF2.F2_PDV "
	cQry += " 										 									AND SL1.L1_FILIAL = SF2.F2_FILIAL "
	cQry += "  										 									AND SL1.D_E_L_E_T_ <> '*' "
	cQry += " 										 									) "

	cQry += " WHERE SF2.D_E_L_E_T_	<> '*'"
	cQry += " AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"'"

	If !Empty(cGet4) //Produtos

		cQry += " AND (SF2.F2_DOC + SF2.F2_SERIE + SF2.F2_CLIENTE + SF2.F2_LOJA	IN (SELECT"
		cQry += "																	DISTINCT SF2_2.F2_DOC + SF2_2.F2_SERIE + SF2_2.F2_CLIENTE + SF2_2.F2_LOJA"
		cQry += "																	FROM "+RetSqlName("SF2")+" SF2_2, "+RetSqlName("SD2")+" SD2"
		cQry += "																	WHERE SF2_2.D_E_L_E_T_	<> '*'"
		cQry += "																	AND SD2.D_E_L_E_T_		<> '*'"
		cQry += " 																	AND SF2_2.F2_FILIAL		= '"+xFilial("SF2")+"'"
		cQry += " 																	AND SD2.D2_FILIAL		= '"+xFilial("SD2")+"'"
		cQry += "																	AND SF2_2.F2_DOC		= SD2.D2_DOC"
		cQry += "																	AND SF2_2.F2_SERIE		= SD2.D2_SERIE"
		cQry += "																	AND SF2_2.F2_CLIENTE	= SD2.D2_CLIENTE"
		cQry += "																	AND SF2_2.F2_LOJA		= SD2.D2_LOJA"

		If !Empty(cGet4) //Produtos
			cProd := FormatIN(cGet4,"/") 
			cQry += "																AND SD2.D2_COD			IN "+cProd+""
		Endif

		cQry += "																	)"
		cQry += " OR SF2.F2_DOC + SF2.F2_SERIE + SF2.F2_CLIENTE + SF2.F2_LOJA IS NULL)"
	Endif

	If !Empty(cGet1) //CNPJ/CGC
		cQry += " AND SA1.A1_CGC = '"+cGet1+"'"
	Endif

	If !Empty(cGet2) //Cliente
		cCli := FormatIN(cGet2,"/")
		cQry += " AND SF2.F2_CLIENTE+SF2.F2_LOJA IN "+cCli+""
	Endif

	If !Empty(cGet3) //Forma de Pagamento
		cFormaPg := FormatIN(cGet3,"/") 
		cQry += " AND SE1.E1_TIPO 	IN "+cFormaPg+""
	Endif

	If !Empty(dGet5) //Dt. Emissão - De
		cQry += " AND SF2.F2_EMISSAO >= '"+DToS(dGet5)+"'"
	Endif

	If !Empty(dGet6) //Dt. Emissão - Ate
		cQry += " AND SF2.F2_EMISSAO <= '"+DToS(dGet6)+"'"
	Endif

	If !Empty(cGet7) //Documento - De
		cQry += " AND SF2.F2_DOC 	>= '"+cGet7+"'"
	Endif

	If !Empty(cGet8) //Documento - Ate
		cQry += " AND SF2.F2_DOC 	<= '"+cGet8+"'"
	Endif

	If !Empty(cGet9) //Placa
		cQry += " AND SL1.L1_PLACA = '"+StrTran(cGet9,"-","")+"'"
	Endif

	If !Empty(nGet10) //Valor - De
		cQry += " AND SF2.F2_VALBRUT >= '"+cValToChar(nGet10)+"'"
	Endif

	If !Empty(nGet11) //Valor - Ate
		cQry += " AND SF2.F2_VALBRUT <= '"+cValToChar(nGet11)+"'"
	Endif

	If lCheckBox1 .And. lCheckBox2
		//cQry += " AND (SF2.F2_SERIE = '1' OR SF2.F2_SERIE = '4' OR SF2.F2_SERIE = '5')" //NF-e Ou NFC-e
		cQry += " AND SF2.F2_ESPECIE IN ('NFCE','SPED')" //NF-e Ou NFC-e
	ElseIf lCheckBox1 .And. !lCheckBox2
		//cQry += " AND (SF2.F2_SERIE = '1' OR SF2.F2_SERIE = '4')" //NF-e
		cQry += " AND SF2.F2_ESPECIE IN ('SPED')" //NF-e
	ElseIf !lCheckBox1 .And. lCheckBox2
		//cQry += " AND SF2.F2_SERIE = '5'" //NFC-e
		cQry += " AND SF2.F2_ESPECIE IN ('NFCE')" //NFC-e
	Endif

	cQry += " ORDER BY 3,2"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RFATE007.txt",cQry)
	TcQuery cQry NEW Alias "QRYDOC"

	If QRYDOC->(!EOF())

		While QRYDOC->(!EOF())

			IncProc()

			//Valida filtro de produtos
			If !Empty(cGet4) .And. lCheckBox3 //Obriga os itens dos Cupons serem exatamente os produtos selecionados
				If !SoProd(QRYDOC->F2_FILIAL,QRYDOC->F2_DOC,QRYDOC->F2_SERIE,QRYDOC->F2_CLIENTE,QRYDOC->F2_LOJA)
					QRYDOC->(DbSkip())
					Loop
				Endif
			Endif

			//Legenda Documento
			If AllTrim(QRYDOC->F2_ESPECIE) == 'SPED' //NF-e
				oLegDoc := oLaranja
			Else
				oLegDoc := oAmarelo
			Endif

			//Legenda Status
			Do Case
			Case QRYDOC->F3_CODRSEF == "100" //Autorizadas
				oLegStatus := oVerde

			Case QRYDOC->F3_CODRSEF == "101" //Canceladas
				oLegStatus := oAzul

			Case QRYDOC->F3_CODRSEF == "102" //Inutilizadas (nao faz sentido pois nao tem SF2/SD2)
				oLegStatus := oMarrom

			Case QRYDOC->F3_CODRSEF == "110" //Denegadas (nao faz sentido pois nao tem SF2/SD2)
				oLegStatus := oPreto

			Case Empty(QRYDOC->F3_CODRSEF) 
				if !empty(QRYDOC->F3_DTCANC) //Canceladas
					oLegStatus := oAzul
				elseif !empty(QRYDOC->F3_CHVNFE) //Autorizadas
					oLegStatus := oVerde
				else
					oLegStatus := oBranco //Status ausente
				endif
			EndCase
			
			aContent := FWGetSX5("05", QRYDOC->E1_TIPO) // Vetor com os dados do SX5com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO
			If Len(aContent)>0 //SX5->(DbSeek(cFilAnt+"05"+QRYDOC->E1_TIPO)) //Compartilhado
				cTpTit := aContent[1][4] //SX5->X5_DESCRI
			Else
				cTpTit := Space(55)
			Endif

			aAdd(aReg,{.F.,; 															//[1]
						oLegDoc,;  														//[2]
						oLegStatus,;													//[3]
						QRYDOC->F2_DOC,; 												//[4]
						QRYDOC->F2_SERIE,; 												//[5]
						QRYDOC->F2_CLIENTE,; 											//[6]
						QRYDOC->F2_LOJA,; 												//[7]
						AllTrim(QRYDOC->A1_NOME),; 										//[8]
						Transform(QRYDOC->A1_CGC,"@R 99.999.999/9999-99"),;				//[9]
						Transform(QRYDOC->VLR_DOC,"@E 9,999,999,999,999.99"),; 			//[10]
						DToC(SToD(QRYDOC->F2_EMISSAO)),; 								//[11]
						Transform(QRYDOC->L1_PLACA,"@!R NNN-9N99"),; 					//[12]
						QRYDOC->E1_TIPO,; 												//[13]
						cTpTit,;														//[14]
						QRYDOC->RECNO})	 												//[15]

			QRYDOC->(DbSkip())
		EndDo
	Else
		aReg := {{.F.,oBranco,oBranco,Space(9),Space(3),Space(6),Space(2),Space(40),Space(14),0,CToD(""),Space(8),Space(3),Space(55),Space(9)}}
	Endif

	If Len(aReg) == 0
		aReg := {{.F.,oBranco,oBranco,Space(9),Space(3),Space(6),Space(2),Space(40),Space(14),0,CToD(""),Space(8),Space(3),Space(55),Space(9)}}
	Endif

	oBrw:SetArray(aReg)
	oBrw:bLine := {|| {IIF(aReg[oBrw:nAT][1],oMark,oNoMark),aReg[oBrw:nAT][2],aReg[oBrw:nAT][3],aReg[oBrw:nAT][4],aReg[oBrw:nAT][5],;
						aReg[oBrw:nAT][6],aReg[oBrw:nAT][7],aReg[oBrw:nAT][8],aReg[oBrw:nAT][9],aReg[oBrw:nAT][10],aReg[oBrw:nAT][11],;
						aReg[oBrw:nAT][12],aReg[oBrw:nAT][13],aReg[oBrw:nAT][14],aReg[oBrw:nAT][15]}}

	oBrw:nAt := 1
	oBrw:Refresh()

	oSay12:Refresh() //Contador
	oSay14:Refresh() //Totalizador

	If Select("QRYDOC") > 0
		QRYDOC->(dbCloseArea())
	Endif

	//Atualiza os itens conforme o cupom posicionado
	BuscaItens()

	oButton7:lVisible 	:= .T.
	oButton8:lVisible 	:= .T.
	oButton9:lVisible 	:= .T.
	oButton10:lVisible 	:= .F.
	oButton11:lVisible 	:= .T.

	oBrw:SetFocus()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} BuscaItens
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function BuscaItens()

	Local cQry 		:= ""

	Local nPosDoc	:= Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosSer	:= Ascan(aCabec,{|x| AllTrim(x) == "Serie"})
	Local nPosCli	:= Ascan(aCabec,{|x| AllTrim(x) == "Cliente"})
	Local nPosLoja	:= Ascan(aCabec,{|x| AllTrim(x) == "Loja"})

	aSize(aReg2,0) //Limpa o array

	If Select("QRYITENS") > 0
		QRYITENS->(dbCloseArea())
	Endif

	cQry := "SELECT SD2.D2_COD,"
	cQry += " SB1.B1_DESC,"
	cQry += " SD2.D2_UM,"
	cQry += " SD2.D2_QUANT,"
	cQry += " SD2.D2_PRUNIT,"
	cQry += " SD2.D2_DESCON,"
	cQry += " SD2.D2_TOTAL"
	cQry += " FROM "+RetSqlName("SD2")+" SD2, "+RetSqlName("SB1")+" SB1"
	cQry += " WHERE SD2.D_E_L_E_T_	<> '*'"
	cQry += " AND SB1.D_E_L_E_T_	<> '*'"
	cQry += " AND SD2.D2_FILIAL		= '"+xFilial("SD2")+"'"
	cQry += " AND SB1.B1_FILIAL		= '"+xFilial("SB1")+"'"
	cQry += " AND SD2.D2_COD		= SB1.B1_COD"
	cQry += " AND SD2.D2_DOC		= '"+aReg[oBrw:nAT][nPosDoc]+"'"
	cQry += " AND SD2.D2_SERIE		= '"+aReg[oBrw:nAT][nPosSer]+"'"
	cQry += " AND SD2.D2_CLIENTE	= '"+aReg[oBrw:nAT][nPosCli]+"'"
	cQry += " AND SD2.D2_LOJA		= '"+aReg[oBrw:nAT][nPosLoja]+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RFATE006_2.txt",cQry)
	TcQuery cQry NEW Alias "QRYITENS"

	If QRYITENS->(!EOF())

		While QRYITENS->(!EOF())

			IncProc()

			aAdd(aReg2,{QRYITENS->D2_COD,; 																					//[1]
						QRYITENS->B1_DESC,; 																				//[2]
						QRYITENS->D2_UM,;	 																				//[3]
						Transform(QRYITENS->D2_QUANT,"@E 999,999.99999999"),; 												//[4]
						Transform(QRYITENS->D2_PRUNIT,"@E 99,999,999.99999999"),; 					   						//[5]
						Transform(A410Arred(QRYITENS->D2_QUANT * QRYITENS->D2_PRUNIT,"L2_VLRITEM"),"@E 999,999,999.99"),; 	//[6]
						Transform(QRYITENS->D2_DESCON,"@E 99,999,999.99999999"),;											//[7]
						Transform(QRYITENS->D2_TOTAL,"@E 999,999,999.99")})													//[8]

			QRYITENS->(dbSkip())
		EndDo
	Else
		aReg2 := {{Space(15),Space(30),Space(2),0,0,0,0,0}}
	Endif

	If Len(aReg2) == 0
		aReg2 := {{Space(15),Space(30),Space(2),0,0,0,0,0}}
	Endif

	oBrw2:SetArray(aReg2)
	oBrw2:bLine := {|| {aReg2[oBrw2:nAT][1],aReg2[oBrw2:nAT][2],aReg2[oBrw2:nAT][3],aReg2[oBrw2:nAT][4],aReg2[oBrw2:nAT][5],;
						aReg2[oBrw2:nAT][6],aReg2[oBrw2:nAT][7],aReg2[oBrw2:nAT][8]}}

	oBrw2:Refresh()

	If Select("QRYITENS") > 0
		QRYITENS->(dbCloseArea())
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FilCli
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FilCli()

//																	cTitulo, 	cAlias,cColunas, 					  cOrdem,					cCond			,cInf
	MsgRun("Selecionando registros...","Aguarde",{|| cGet2 := U_UMultSel("Clientes","SA1","A1_COD,A1_LOJA,A1_NOME,A1_CGC","A1_NOME,A1_COD,A1_LOJA","A1_MSBLQL = '2'",cGet2)})
	oGet2:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FilFormaPg
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FilFormaPg()

//																	cTitulo, 			  cAlias,cColunas	  		,cOrdem     ,cCond				,cInf
	MsgRun("Selecionando registros...","Aguarde",{|| cGet3 := U_UMultSel("Formas de Pagamento","SX5","X5_CHAVE,X5_DESCRI","X5_DESCRI","X5_TABELA = '24'",cGet3)})
	oGet3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FilProd
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FilProd()

//																	cTitulo,    cAlias,cColunas	  	 ,cOrdem    ,cCond	  		  ,cInf
	MsgRun("Selecionando registros...","Aguarde",{|| cGet4 := U_UMultSel("Produtos","SB1","B1_COD,B1_DESC","B1_DESC","B1_MSBLQL <> '1'",cGet4)})
	oGet4:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarkReg
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarkReg()

	Local nPosDoc := Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosVlr := Ascan(aCabec,{|x| AllTrim(x) == "Valor"})

	If !Empty(aReg[oBrw:nAT][nPosDoc]) //Documento/Registro válido
		If aReg[oBrw:nAT][1]
			aReg[oBrw:nAT][1] := .F.
			nCont--
			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlr],".",""),",",".")) > 0
				nTot -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlr],".",""),",",".")) //Valor
			Endif
		Else
			aReg[oBrw:nAT][1] := .T.
			nCont++
			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlr],".",""),",",".")) > 0
				nTot += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlr],".",""),",",".")) //Valor
			Endif
		Endif
	Endif

	oBrw:Refresh()
	oSay12:Refresh()
	oSay14:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarkAllReg
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarkAllReg()

	Local nI
	Local nPosDoc := Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosVlr := Ascan(aCabec,{|x| AllTrim(x) == "Valor"})

	nCont	:= 0
	nTot  	:= 0

	If !Empty(aReg[oBrw:nAT][nPosDoc]) //Filial/Registro válido
		If aReg[oBrw:nAT][1]
			For nI := 1 To Len(aReg)
				aReg[nI][1] := .F.
			Next
		Else
			For nI := 1 To Len(aReg)
				aReg[nI][1] := .T.
				nCont++

				If Val(StrTran(StrTran(aReg[nI][nPosVlr],".",""),",",".")) > 0
					nTot += Val(StrTran(StrTran(aReg[nI][nPosVlr],".",""),",",".")) //Valor
				Endif
			Next
		Endif
	Endif

	oBrw:Refresh()
	oSay12:Refresh()
	oSay14:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} VisDoc
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function VisDoc()

	Local nI
	Local nContDoc	:= 0
	Local lAux 		:= .T.

	Local nPosDoc	:= Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosSerie	:= Ascan(aCabec,{|x| AllTrim(x) == "Serie"})
	Local nPosCli	:= Ascan(aCabec,{|x| AllTrim(x) == "Cliente"})
	Local nPosLoja	:= Ascan(aCabec,{|x| AllTrim(x) == "Loja"})

	For nI := 1 To Len(aReg)
		If aReg[nI][1] == .T.
			nContDoc++
		Endif
	Next

	If nContDoc == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	ElseIf nContDoc > 1
		MsgInfo("A visualização do documento deve ser realizada para um registro de cada vez.","Atenção")
		lAux := .F.
	Endif

	If lAux
		If !Empty(aReg[oBrw:nAT][nPosDoc])

			DbSelectArea("SF2")
			SF2->(DbSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO

			If SF2->(DbSeek(xFilial("SF2")+aReg[oBrw:nAT][nPosDoc]+aReg[oBrw:nAT][nPosSerie]+aReg[oBrw:nAT][nPosCli]+aReg[oBrw:nAT][nPosLoja]))
				Mc090Visual("SF2",SF2->(Recno()),1)
			Else
				MsgInfo("Documento não localizado.","Atenção")
			Endif
		Endif
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ExpXML
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ExpXML()

	Local nI
	Local nContXML		:= 0
	Local lAux 			:= .T.
	Local nRet			:= 0

	Local aPerg			:= {}
	Local aParam		:= {Space(60)}
	Local cParNfeExp	:= SM0->M0_CODIGO+SM0->M0_CODFIL+"SPEDNFEEXP"

	Local cDrive		:= ""
	Local cDestino 		:= ""

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.
			nContXML++
		Endif
	Next

	If nContXML == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	If lAux

		AAdd(aPerg,{6,"Diretório de destino",aParam[01],"",".T.","!Empty(mv_par01)",80,.T.,"Arquivos XML |*.XML","",GETF_RETDIRECTORY+GETF_LOCALHARD })
		aParam[01] := ParamLoad(cParNfeExp,aPerg,1,aParam[01])

		If ParamBox(aPerg,"Exporta - XML",@aParam,,,,,,,cParNfeExp,.T.,.T.)

			//Corrigi diretorio de destino
			SplitPath(aParam[01],@cDrive,@cDestino,"","")
			cDestino := cDrive+cDestino

			MsgRun("Gerando arquivos...","Aguarde",{|| nRet := GeraXML(cDestino),IIF(nRet > 0,MsgInfo("Processamento concluído.","Atenção"),MsgInfo("Nenhum arquivo gerado.","Atenção"))})
		Endif
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraXML
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GeraXML(cDestino)

	Local nContArq		:= 0
	Local nI,nX,oAux

	Local nPosDoc		:= Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosSerie		:= Ascan(aCabec,{|x| AllTrim(x) == "Serie"})
	Local nPosNomCli	:= Ascan(aCabec,{|x| AllTrim(x) == "Nome"})
	//Local nPosEmi		:= Ascan(aCabec,{|x| AllTrim(x) == "Emissao"})
	Local nPosRecNo		:= Ascan(aCabec,{|x| AllTrim(x) == "R_E_C_N_O_"})

	Local cEndereco		:= ""
	Local cModelo		:= ""
	Local nHandle  		:= 0
	Local oRetorno
	Local oWS
	Local oXML
	Local cXML			:= ""
	Local lOk      		:= .F.
	Local cIdEnt		:= ""
	Local cArquivo 		:= ""
	Local cMV_NFCEURL	:= GetMv("MV_NFCEURL")
	Local cMV_SPEDURL	:= GetMv("MV_SPEDURL")

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.

			SF2->(DbGoTo(aReg[nI][nPosRecNo]))

			//verifico se vem do Kingposto, e sem tem o XML gravado
			MHQ->(DbSetOrder(1)) //MHQ_FILIAL+MHQ_ORIGEM+MHQ_CPROCE+MHQ_CHVUNI+MHQ_EVENTO+DTOS(MHQ_DATGER)+MHQ_HORGER
			if MHQ->(DbSeek(xFilial("MHQ")+PadR("KINGPOSTO",TamSX3("MHQ_ORIGEM")[1])+PadR("XML",TamSX3("MHQ_CPROCE")[1])+SF2->F2_FILIAL+SF2->F2_SERIE+SF2->F2_DOC ))
				cXML := MHQ->MHQ_MENSAG
				cChvNFe := NfeIdSPED(cXML,"Id")

				cModelo := cChvNFe
				cModelo := StrTran(cModelo,"NFe","")
				cModelo := StrTran(cModelo,"CTe","")
				cModelo := SubStr(cModelo,21,02)

				Do Case
				Case cModelo == "65"
					cPrefixo := "NFCe"
				OtherWise
					If '<cStat>301</cStat>' $ cXML .or. '<cStat>302</cStat>' $ cXML //denegada
						cPrefixo := "den"
					Else
						cPrefixo := "NFe"
					Endif
				EndCase

				cArquivo := SubStr(AllTrim(aReg[nI][nPosNomCli]),1,35)+"-"+AllTrim(aReg[nI][nPosDoc])+"-"+AllTrim(aReg[nI][nPosSerie])+"-"+cPrefixo+".xml"
				cArquivo := NoCharInv(cArquivo) //Remove caracteres especiais inválidos para nome de arquivos e pastas

				if FILE(cDestino+cArquivo)
					FErase(cDestino+cArquivo)
				ENDIF

				nHandle := FCreate(cDestino+cArquivo)

				If nHandle > 0
					FWrite(nHandle, cXML )
					FClose(nHandle)

					nContArq++
					LOOP
				EndIf
			endif

			//---------------------------
			// Obtem o URL do TSS
			//---------------------------
			If !Empty(SF2->F2_PDV) // Advindo do TOTVS PDV
				cEndereco := cMV_NFCEURL
			Else // Retaguarda
				cEndereco := cMV_SPEDURL
			EndIf

			//---------------------------
			// Obtem o codigo da entidade
			//---------------------------
			If Empty(SF2->F2_PDV)
				cIdEnt := RetIdEnti()
			Else // Advindo do TOTVS PDV
				If FindFunction("LjTSSIDEnt")
					cIdEnt := LjTSSIDEnt(IIF(SF2->F2_ESPECIE=="SPED","55","65"))
				Else
					//cIdEnt := StaticCall(LOJNFCE,LjTSSIDEnt,IIF(SF2->F2_ESPECIE=="SPED","55","65"))
					cIdEnt := &("StaticCall(LOJNFCE,LjTSSIDEnt,'" + IIF(SF2->F2_ESPECIE=="SPED","55","65") + "')")
				EndIf
			EndIf

			oWS:= WSNFeSBRA():New()
			oWS:cUSERTOKEN        	:= "TOTVS"
			oWS:cID_ENT           	:= cIdEnt
			oWS:_URL              	:= AllTrim(cEndereco)+"/NFeSBRA.apw"
			oWS:cIdInicial        	:= aReg[nI][nPosSerie] + aReg[nI][nPosDoc]
			oWS:cIdFinal          	:= aReg[nI][nPosSerie] + aReg[nI][nPosDoc]
			oWS:dDataDe           	:= CToD("19000101") //CToD(aReg[nI][nPosEmi])
			oWS:dDataAte          	:= CToD("20991231") //CToD(aReg[nI][nPosEmi])
			oWS:cCNPJDESTInicial  	:= "              "
			oWS:cCNPJDESTFinal    	:= "99999999999999"
			oWS:nDiasparaExclusao 	:= 0

			lOk			:= oWS:RETORNAFX()
			oRetorno	:= oWS:oWsRetornaFxResult

			If lOk

				For nX := 1 To Len(oRetorno:OWSNOTAS:OWSNFES3)

					oXml    := oRetorno:OWSNOTAS:OWSNFES3[nX]
					oXmlExp := XmlParser(oRetorno:OWSNOTAS:OWSNFES3[nX]:OWSNFE:CXML,"","","")
					cXML	:= ""
					//cVerNfe := IIF(Type("oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT") <> "U", oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT, '')
					cVerNfe	:= ""
					if (oAux := XmlChildEx(oXmlExp,"_NFE"))!=Nil .AND. ;
            			(oAux := XmlChildEx(oAux,"_INFNFE"))!=Nil .AND. ;
            			(oAux := XmlChildEx(oAux,"_VERSAO"))!=Nil 

						cVerNfe := oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT
					endif

					If !Empty(oXml:oWSNFe:cProtocolo)

						cChvNFe := NfeIdSPED(oXml:oWSNFe:cXML,"Id")
						cModelo := cChvNFe
						cModelo := StrTran(cModelo,"NFe","")
						cModelo := StrTran(cModelo,"CTe","")
						cModelo := SubStr(cModelo,21,02)

						Do Case
						Case cModelo == "65"
							cPrefixo := "NFCe"
						OtherWise
							If '<cStat>301</cStat>' $ oXml:oWSNFe:cxmlPROT .or. '<cStat>302</cStat>' $ oXml:oWSNFe:cxmlPROT
								cPrefixo := "den"
							Else
								cPrefixo := "NFe"
							Endif
						EndCase

						cArquivo := SubStr(AllTrim(aReg[nI][nPosNomCli]),1,35)+"-"+AllTrim(aReg[nI][nPosDoc])+"-"+AllTrim(aReg[nI][nPosSerie])+"-"+cPrefixo+".xml"
						cArquivo := NoCharInv(cArquivo) //Remove caracteres especiais inválidos para nome de arquivos e pastas

						if FILE(cDestino+cArquivo)
							FErase(cDestino+cArquivo)
						ENDIF

						nHandle := FCreate(cDestino+cArquivo)

						If nHandle > 0

							cCab1 := '<?xml version="1.0" encoding="UTF-8"?>'

							Do Case
							Case cVerNfe <= "1.07"
								cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.portalfiscal.inf.br/nfe procNFe_v1.00.xsd" versao="1.00">'
							Case cVerNfe >= "2.00" .And. "cancNFe" $ oXml:oWSNFe:cXML
								cCab1 += '<procCancNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
							OtherWise
								cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
							EndCase

							cRodap := '</nfeProc>'

							FWrite(nHandle,AllTrim(cCab1))
							FWrite(nHandle,AllTrim(oXml:oWSNFe:cXML))
							FWrite(nHandle,AllTrim(oXml:oWSNFe:cXMLPROT))
							FWrite(nHandle,AllTrim(cRodap))
							FClose(nHandle)

							nContArq++
						EndIf
					Endif

					FreeObj(oXML)
					FreeObj(oXmlExp)
				Next nX
			Endif

			FreeObj(oWS)
			FreeObj(oRetorno)
		Endif
	Next nI

Return nContArq

//-------------------------------------------------------------------
/*/{Protheus.doc} NoCharInv
Remove caracteres especiais inválidos para nome de arquivos e pastas
Tratamento para caracteres inválidos para a criação de arquivos e pastas

Os caracteres que afetam o "parser" são:
• \ (barra invertida)
• / (barra)
• | (pipe)
• > (sinal de maior)
• < (sinal de menor)
• * (asterisco)
• " (aspas)
• ' (sinal de apóstrofo)
• ? (interrogação)
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function NoCharInv(cString)

	cString := (StrTran(cString,"\",""))
	cString := (StrTran(cString,"/",""))
	cString := (StrTran(cString,"|",""))
	cString := (StrTran(cString,">",""))
	cString := (StrTran(cString,"<",""))
	cString := (StrTran(cString,"*",""))
	cString := (StrTran(cString,'"',""))
	cString := (StrTran(cString,"'",""))
	cString := (StrTran(cString,"?",""))

Return(cString)

//-------------------------------------------------------------------
/*/{Protheus.doc} ImpDoc
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ImpDoc()

	Local nI
	Local nContReg	:= 0
	Local lAux 		:= .T.

	//Local aPerg			:= {}
	//Local aParam		:= {Space(60)}
	//Local cParNfeExp	:= SM0->M0_CODIGO+SM0->M0_CODFIL+"SPEDNFEEXP"

	//Local cDrive		:= ""
	Local cDestino 		:= ""
	Local oSetup, nFlags, nRet

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.
			nContReg++
		Endif
	Next

	If nContReg == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	If lAux

//	AAdd(aPerg,{6,"Diretório de destino",aParam[01],"",".T.","!Empty(mv_par01)",80,.T.,"Arquivos XML |*.XML","",GETF_RETDIRECTORY+GETF_LOCALHARD,.T.}) //"Diretório de destino"
//	aParam[01] := ParamLoad(cParNfeExp,aPerg,1,aParam[01])
//
//	If ParamBox(aPerg,"Imprime - PDF",@aParam,,,,,,,cParNfeExp,.T.,.T.)
//
//		//Corrigi diretorio de destino
//		SplitPath(aParam[01],@cDrive,@cDestino,"","")
//		cDestino := cDrive+cDestino
//
//		//MsgRun("Imprimindo arquivos...","Aguarde",{|| nRet := GeraPDF(cDestino),IIF(nRet > 0,MsgInfo("Processamento concluído.","Atenção"),MsgInfo("Nenhum arquivo impresso.","Atenção"))})
//		nRet := GeraPDF(cDestino)
//		IIF(nRet > 0,MsgInfo("Processamento concluído.","Atenção"),MsgInfo("Nenhum arquivo impresso.","Atenção"))
//	Endif

		nFlags:= PD_ISTOTVSPRINTER + PD_DISABLEDESTINATION + PD_DISABLEORIENTATION + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
		oSetup:= FWPrintSetup():New(nFlags,"IMPRESSAO AUTOMATICA BOLETO/DANFE")
		oSetup:SetPropert(PD_PRINTTYPE   , IMP_PDF)
		oSetup:SetPropert(PD_DESTINATION , 2) //CLIENT
		oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
		oSetup:CQTDCOPIA := "01"
		//oSetup:aOptions[6] := cDestino

		If oSetup:Activate() == PD_OK
			cDestino := oSetup:aOptions[6]
			MsgRun("Imprimindo arquivos...","Aguarde",{|| nRet := GeraPDF(cDestino,oSetup) })
			IIF(nRet > 0,MsgInfo("Processamento concluído.","Atenção"),MsgInfo("Nenhum arquivo impresso.","Atenção"))
		endif

		FreeObj(oSetup)
		oSetup := Nil
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraPDF
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GeraPDF(cDestino,oSetup)

	Local aArea				:= GetArea()
	Local nRet 				:= 0
	Local nI
	Local nPosDoc			:= Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosSerie			:= Ascan(aCabec,{|x| AllTrim(x) == "Serie"})
	Local nPosEmi			:= Ascan(aCabec,{|x| AllTrim(x) == "Emissao"})
	Local nPosRecNo			:= Ascan(aCabec,{|x| AllTrim(x) == "R_E_C_N_O_"})
	Local oBjNfe
	Local cPath 			:= cDestino //cTmpUser
	Local lAdjustToLegacy	:= .T.
	Local cURL     			:= ""
	Local oRetorno
	Local oWS
	Local oPrint
	Local nBkpCont			:= nCont
	Local aRet

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.

			cEspecie := LjRetEspec(aReg[nI][nPosSerie])
			
			If "SPED" $ cEspecie //NF-e

				Pergunte("NFSIGW",.F.)
				SetMVValue("NFSIGW","MV_PAR01",aReg[nI][nPosDoc]) // Da Nota Fiscal ?
				SetMVValue("NFSIGW","MV_PAR02",aReg[nI][nPosDoc]) // Ate a Nota Fiscal ?
				SetMVValue("NFSIGW","MV_PAR03",aReg[nI][nPosSerie]) // Da Serie ?
				SetMVValue("NFSIGW","MV_PAR04",2) //Tipo de Operacao ? (1)Entrada / (2)Saida
				SetMVValue("NFSIGW","MV_PAR07",CtoD(aReg[nI][nPosEmi])) //data emissao de
				SetMVValue("NFSIGW","MV_PAR08",CtoD(aReg[nI][nPosEmi])) //data emissao ate
				Pergunte("NFSIGW",.F.) 

				//Apaga arquivo se já existir
				FErase(/*cTmpUser*/cDestino + AllTrim(aReg[nI][nPosSerie])+AllTrim(aReg[nI][nPosDoc]) + ".rel")
				FErase(/*cTmpUser*/cDestino + AllTrim(aReg[nI][nPosSerie])+AllTrim(aReg[nI][nPosDoc]) + ".pdf")

				cFilePrint	:= AllTrim(aReg[nI][nPosSerie])+AllTrim(aReg[nI][nPosDoc])
				oBjNfe		:= FWMSPrinter():New(cFilePrint /*Nome Arq*/, IMP_PDF /*IMP_SPOOL/IMP_PDF*/, .F. /*3-Legado*/,;
							/*4-Dir. Salvar*/, .T. /*5-Não Exibe Setup*/, /*6-Classe TReport*/,;
							oSetup /*7-oPrintSetup*/, ""  /*8-Impressora Forçada*/,;
							.F. /*lServer*/, /*lPDFAsPNG*/, /*lRaw*/, .F. /*lViewPDF*/)
				oBjNfe:SetResolution(78) //Tamanho estipulado para a Danfe
				oBjNfe:SetPortrait()
				oBjNfe:SetPaperSize(DMPAPER_A4)
				oBjNfe:nDevice 	:= IMP_PDF
				oBjNfe:cPathPDF := cDestino //cTmpUser

				SF2->(DbGoTo(aReg[nI][nPosRecNo]))

				//---------------------------
				// Obtem o codigo da entidade
				//---------------------------
				If Empty(SF2->F2_PDV)
					cIdEnt := RetIdEnti()
				Else // Advindo do TOTVS PDV
					If FindFunction("LjTSSIDEnt")
						cIdEnt := LjTSSIDEnt(IIF(SF2->F2_ESPECIE=="SPED","55","65"))
					Else
						//cIdEnt := StaticCall(LOJNFCE,LjTSSIDEnt,IIF(SF2->F2_ESPECIE=="SPED","55","65"))
						cIdEnt := &("StaticCall(LOJNFCE,LjTSSIDEnt,'" + IIF(SF2->F2_ESPECIE=="SPED","55","65") + "')")
					EndIf
				EndIf

				If U_PrtNfeSef(cIdEnt, "", "", oBjNfe, oSetup/*oSetup*/, cFilePrint, .T., 0) //Rdmake de exemplo para impressão da DANFE no formato Retrato
					nRet++
				Endif

				//-- destroi os objetos
				//FreeObj(oSetup)
				//oSetup := Nil
				FreeObj(oBjNfe)
				oBjNfe := Nil

			ElseIf "NFCE" $ cEspecie //NFC-e

				cXML := ""
				cXMLProt := ""
				SF2->(DbGoTo(aReg[nI][nPosRecNo]))

				//verifico se vem do Kingposto, e sem tem o XML gravado
				MHQ->(DbSetOrder(1)) //MHQ_FILIAL+MHQ_ORIGEM+MHQ_CPROCE+MHQ_CHVUNI+MHQ_EVENTO+DTOS(MHQ_DATGER)+MHQ_HORGER
				if MHQ->(DbSeek(xFilial("MHQ")+PadR("KINGPOSTO",TamSX3("MHQ_ORIGEM")[1])+PadR("XML",TamSX3("MHQ_CPROCE")[1])+SF2->F2_FILIAL+SF2->F2_SERIE+SF2->F2_DOC ))
					cXML := MHQ->MHQ_MENSAG

					cXMLProt := SubStr(cXml, At("<protNFe ",cXml),At("</protNFe>",cXml) - At("<protNFe ",cXml) + 10)
					cXML := SubStr(cXml, At("<NFe ",cXml),At("</NFe>",cXml) - At("<NFe ",cXml) + 6)
					
				endif

				if empty(cXML) .AND. empty(cXMLProt)

					cURL := PadR(GetNewPar("MV_NFCEURL","http://"),250)

					//---------------------------
					// Obtem o codigo da entidade
					//---------------------------
					If FindFunction("LjTSSIDEnt")
						cIdEnt := LjTSSIDEnt("65")
					Else
						//cIdEnt := StaticCall(LOJNFCE, LjTSSIDEnt, "65")
						cIdEnt := &("StaticCall(LOJNFCE, LjTSSIDEnt, '65')")
					EndIf

					If cIdEnt == Nil .OR. empty(cIdEnt)
						MsgInfo("Não foi possível encontrar a entidade da NFCe")
						LOOP
					endif

					oWS:= WSNFeSBRA():New()
					oWS:cUSERTOKEN        	:= "TOTVS"
					oWS:cID_ENT           	:= cIdEnt
					oWS:_URL              	:= AllTrim(cURL)+"/NFeSBRA.apw"
					oWS:cIdInicial        	:= aReg[nI][nPosSerie] + aReg[nI][nPosDoc]
					oWS:cIdFinal          	:= aReg[nI][nPosSerie] + aReg[nI][nPosDoc]
					oWS:dDataDe           	:= CToD("19000101") //CToD(aReg[nI][nPosEmi])
					oWS:dDataAte          	:= CToD("20991231") //CToD(aReg[nI][nPosEmi])
					oWS:cCNPJDESTInicial  	:= "              "
					oWS:cCNPJDESTFinal    	:= "99999999999999"
					oWS:nDiasparaExclusao 	:= 0

					lOk			:= oWS:RETORNAFX()
					oRetorno	:= oWS:oWsRetornaFxResult

					If lOk
						cXML := oRetorno:OWSNOTAS:OWSNFES3[1]:OWSNFE:CXML
						cXMLProt := oRetorno:OWSNOTAS:OWSNFES3[1]:OWSNFE:CXMLPROT
					endif

				endif
					
				if !empty(cXML) .AND. !empty(cXMLProt)
					//Apaga arquivo se já existir
					FErase(/*cTmpUser*/cDestino + AllTrim(aReg[nI][nPosSerie])+AllTrim(aReg[nI][nPosDoc]) + ".rel")
					FErase(/*cTmpUser*/cDestino + AllTrim(aReg[nI][nPosSerie])+AllTrim(aReg[nI][nPosDoc]) + ".pdf")

					cFilePrint	:= AllTrim(aReg[nI][nPosSerie])+AllTrim(aReg[nI][nPosDoc])

					oPrint := FWMsPrinter():New(cFilePrint, IMP_PDF, lAdjustToLegacy,cPath,.T., , oSetup, , .F., , , .F.)
					oPrint:SetPortrait()
					oPrint:SetPaperSize(DMPAPER_A4)
					oPrint:cPathPDF := cDestino //cTmpUser

					//chama RDMAKE de NFCe modificado
					aRet := U_LjRDnfNFCe(cXML, cXMLProt, /*cChvNFCe*/, .T./*lDANFEPad*/, {}/*aItensNFCe*/, .F./*lNFe*/, oPrint)
					if aRet[1]
						nRet++
					endif
					
					FreeObj(oPrint)
					oPrint := Nil

				Endif
				
			Endif

		Endif
	Next

	nCont := nBkpCont
	RestArea(aArea)

Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} OrderGrid
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function OrderGrid(oObj,nColum)

	Local nPosDoc	:= Ascan(aCabec,{|x| AllTrim(x) == "Documento"})
	Local nPosSer	:= Ascan(aCabec,{|x| AllTrim(x) == "Serie"})
	Local nPosCli	:= Ascan(aCabec,{|x| AllTrim(x) == "Cliente"})
	Local nPosLoja	:= Ascan(aCabec,{|x| AllTrim(x) == "Loja"})
	Local nPosNome	:= Ascan(aCabec,{|x| AllTrim(x) == "Nome"})
	Local nPosCgc	:= Ascan(aCabec,{|x| AllTrim(x) == "CGC/CPF"})
	Local nPosVlr	:= Ascan(aCabec,{|x| AllTrim(x) == "Valor"})
	Local nPosEmi	:= Ascan(aCabec,{|x| AllTrim(x) == "Emissao"})
	Local nPosPlc	:= Ascan(aCabec,{|x| AllTrim(x) == "Placa"})
	Local nPosTp	:= Ascan(aCabec,{|x| AllTrim(x) == "Tipo"})
	Local nPosDesc	:= Ascan(aCabec,{|x| AllTrim(x) == "Descricao"})
	Local nPosRecno	:= Ascan(aCabec,{|x| AllTrim(x) == "R_E_C_N_O_"})

	If nColum <> 1 .And. nColum <> 2 .And. nColum <> 3 .And. nColum <> nPosRecno //Caixa de seleção e Legenda Doc e Legenda Status e R_E_C_N_O_

		//Valor - N
		If nColum == nPosVlr

			ASort(aReg,,,{|x,y| (StrZero(INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")))) * 1000) + x[nPosNome] ) < ( StrZero(INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")))) * 1000) + y[nPosNome])})

			//Documento ou Série ou Cliente ou Loja ou Nome ou CGC ou Placa ou Tipo ou Descrição - C
		ElseIf nColum == nPosDoc .Or. nColum == nPosSer .Or. nColum == nPosCli .Or. nColum == nPosLoja .Or. nColum == nPosNome .Or. nColum == nPosCgc .Or.;
				nColum == nPosPlc .Or. nColum == nPosTp .Or. nColum == nPosDesc

			ASort(aReg,,,{|x,y| x[nColum] + x[nPosNome] < y[nColum] + y[nPosNome]})

			//Dt. Emissão - D
		ElseIf nColum == nPosEmi

			ASort(aReg,,,{|x,y| DToS(CToD(x[nColum])) + x[nPosNome] < DToS(CToD(y[nColum])) + y[nPosNome]})
		Endif

		oBrw:SetArray(aReg)
		oBrw:bLine := {|| {IIF(aReg[oBrw:nAT][1],oMark,oNoMark),aReg[oBrw:nAT][2],aReg[oBrw:nAT][3],aReg[oBrw:nAT][4],aReg[oBrw:nAT][5],;
			aReg[oBrw:nAT][6],aReg[oBrw:nAT][7],aReg[oBrw:nAT][8],aReg[oBrw:nAT][9],aReg[oBrw:nAT][10],aReg[oBrw:nAT][11],;
			aReg[oBrw:nAT][12],aReg[oBrw:nAT][13],aReg[oBrw:nAT][14],aReg[oBrw:nAT][15]}}

		oBrw:Refresh()
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SoProd
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function SoProd(_cFil,_cDoc,_cSerie,_cCli,_cLojaCli)

	Local lRet := .T.
	Local cQry := ""

	If Select("QRYPROD") > 0
		QRYPROD->(dbCloseArea())
	Endif

	cQry := "SELECT DISTINCT SD2.D2_COD"
	cQry += " FROM "+RetSqlName("SF2")+" SF2, "+RetSqlName("SD2")+" SD2"
	cQry += " WHERE SF2.D_E_L_E_T_	<> '*'"
	cQry += " AND SD2.D_E_L_E_T_	<> '*'"
	cQry += " AND SF2.F2_FILIAL		= '"+_cFil+"'"
	cQry += " AND SD2.D2_FILIAL		= '"+_cFil+"'"
	cQry += " AND SF2.F2_DOC		= SD2.D2_DOC"
	cQry += " AND SF2.F2_SERIE		= SD2.D2_SERIE"
	cQry += " AND SF2.F2_CLIENTE	= SD2.D2_CLIENTE"
	cQry += " AND SF2.F2_LOJA		= SD2.D2_LOJA"
	cQry += " AND SF2.F2_DOC		= '"+_cDoc+"'"
	cQry += " AND SF2.F2_SERIE		= '"+_cSerie+"'"
	cQry += " AND SF2.F2_CLIENTE	= '"+_cCli+"'"
	cQry += " AND SF2.F2_LOJA		= '"+_cLojaCli+"'"
	cQry += " ORDER BY 1"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RFATE007.txt",cQry)
	TcQuery cQry NEW Alias "QRYPROD"

	While QRYPROD->(!EOF())

		If !AllTrim(QRYPROD->D2_COD) $ cGet4
			lRet := .F.
			Exit
		Endif

		QRYPROD->(DbSkip())
	EndDo

	If Select("QRYPROD") > 0
		QRYPROD->(dbCloseArea())
	Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} LjRTemNode
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LjRTemNode(oObjeto,cNode)

	Local lRet := .F.

	lRet := (XmlChildEx(oObjeto,cNode) <> NIL)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} LjUTCtoLoc
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LjUTCtoLoc(cDataUTC)

	Local dData			:= Nil
	Local cHoraMin		:= ""
	Local cSegundos		:= ""
	Local cTZD			:= ""
	Local nTZD			:= 0
	Local dDataLocal	:= Nil
	Local cHoraLocal	:= ""
	Local nHoraLocal	:= 0
	Local cTZDLocal		:= ""
	Local nTZDLocal		:= 0
	Local nHoraUTC		:= 0
	Local cGMTByUF		:= ""

	Local aRet			:= {}
	Local aHoraLocal	:= {}

	Default cDataUTC 	:= ""

	dData 		:= CtoD( SubStr(cDataUTC,9,2) + "/" + SubStr(cDataUTC,6,2) + "/" + SubStr(cDataUTC,1,4) ) //ex: DD/MM/AAAA
	cHoraMin	:= SubStr( cDataUTC, 12, 05 )	//ex: hora e minuto do horario ex: 00:00:xx
	cSegundos	:= SubStr( cDataUTC, 18, 02 )	//ex: segundos do horario ex: xx:xx:00
	cTZD		:= SubStr( cDataUTC, 20, 06 )	//ex: -03:00
	nTZD		:= Val( cTZD )					//ex: -3

	/*
		Fuso horario zero (somamos o TZD para obter o fuso horario zero)
	*/
	nHoraUTC := Val( StrTran(cHoraMin, ":", ".") )
	nHoraUTC := nHoraUTC + (nTZD*(-1))

	/*
		Fuso horario local
	*/
	cGMTByUF := SubStr(FwGMTByUF(), 1, 6)
	cTZDLocal := SuperGetMV("MV_NFCEUTC",,cGMTByUF)
	nTZDLocal := Val(cTZDLocal)

	nHoraLocal := nHoraUTC + nTZDLocal

	If nHoraLocal >= 24
		nHoraLocal := nHoraLocal - 24
		dDataLocal := dData += 1
	Else
		dDataLocal := dData
	EndIf

	// convertemos a hh:mm para o formato Caracter
	cHoraLocal := cValToChar(nHoraLocal)

	// tratamos as horas e minutos
	aHoraLocal := StrToKArr(cHoraLocal, ".")

	aHoraLocal[1] := PadL(aHoraLocal[1], 2, "0")		//acrescenta 0 no inicio da hora
	If Len(aHoraLocal) > 1
		aHoraLocal[2] := PadR(aHoraLocal[2], 2, "0")	//acrescenta 0 no final dos minutos
	Else //se for hora fechada (ex: 08:00), o array somente vai ter uma posição, sendo assim, adicionamos 00 aos Minutos
		Aadd(aHoraLocal, PadR(0, 2, "0"))				//acrescenta 0 no final dos minutos
	EndIf

	// transforma no formato hh:mm:ss
	cHoraLocal := aHoraLocal[1] + ":" + aHoraLocal[2] + ":" + cSegundos

	Aadd(aRet, dDataLocal)
	Aadd(aRet, cHoraLocal)
	Aadd(aRet, cTZDLocal)

Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} LjRetEspec
Retorna a Especie a ser utilizada de acordo com a configuracao dos parametros MV_LOJANF e MV_ESPECIE.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LjRetEspec(_cSerie)
	Local cEspecie 	:= "NF" // Especie da NF
	Local cTiposDoc	:= "" 	// Tipos de documentos fiscais utilizados na emissao de notas fiscais
	Local nCount 	:= 0
	Local nPosSign	:= 0
	Local aContent  := {} // Vetor com os dados do SX5 com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO

	If cPaisLoc == "BRA"
		cTiposDoc := AllTrim( SuperGetMV( 'MV_ESPECIE' ) ) // Tipos de documentos fiscais utilizados na emissao de notas fiscais

		If cTiposDoc <> NIL
			cTiposDoc := StrTran( cTiposDoc, ";", CRLF)

			For nCount := 1 TO MLCount( cTiposDoc )
				cEspecie := ALLTRIM( StrTran( MemoLine( cTiposDoc,, nCount ), CHR(13), CHR(10) ) )
				nPosSign := Rat( "=", cEspecie)

				If nPosSign > 0 .AND. ALLTRIM( _cSerie ) == ALLTRIM( SUBSTR( cEspecie, 1, nPosSign - 1 ) )
					aContent := FWGetSX5("42", SUBSTR(cEspecie, nPosSign + 1)) // Vetor com os dados do SX5 com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO
					If Len(aContent)>0 //SX5->( DbSeek( xFilial("SX5") + "42" + SUBSTR(cEspecie, nPosSign + 1) ) )
						cEspecie := SUBSTR( cEspecie, nPosSign + 1 )
					Else
						cEspecie := SPACE(5)
					Endif
					Exit
				Else
					cEspecie := SPACE(5)
				Endif
			Next nCount

		Endif
	Endif

Return cEspecie

//-------------------------------------------------------------------
/*/{Protheus.doc} LimpMemo
SubFunção - LimpMemo
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LimpMemo(_oObjeto,_cInf)

	_cInf := Space(200)
	_oObjeto:Refresh()

Return

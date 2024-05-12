#include "protheus.ch"
#include "topconn.ch"

Static aCfgCpos1
Static aCfgCpos2
Static nPosFilial, nPosVenda, nPosSerie, nPosCli, nPosLoja, nPosNome, nPosValor, nPosEmissao, nPosPlaca, nPosTipo, nPosNFCup, nPosRecno, nPosObsFat
Static nPosProd, nPosDesc, nPosUn, nPosQtd, nPosVlUnit, nPosTotBr, nPosDescont, nPosTotLi

/*/{Protheus.doc} TRETA042
Gera NF-e

@author Maiki Perin
@since 01/07/2015
@version P11
@param Nao recebe parametros
@return nulo
/*/
User Function TRETA042()

	Local cTitulo 		:= "Gera NF-e"

	Local aCabec		:= U_TRE042CP(1,1) //array com descriçao dos campos do grid
	Local aLarg			:= U_TRE042CP(1,2) //array com largura dos campos do grid

	Local aCabec2		:= U_TRE042CP(2,1) //array com descriçao dos campos do grid
	Local aLarg2		:= U_TRE042CP(2,2) //array com largura dos campos do grid

	Local oBmp1, oBmp2

	Private oFolder042
	Private oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12, oSay13, oSay14, oSay15, oSay16, oSay17, oSay18
	Private oSay19, oSay20, oSay21, oSay22, oSay23, oSay24, oSay25
	Private oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet10, oGet11, oGet12, oGet13, oGet14, oGet15

	Private cGet1 		:= Space(4)
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
	Private nGet12		:= 0
	Private nGet13		:= 0
	Private cGet14 		:= Space(14)
	Private cGet15 		:= ""

	Private lCheckBox1	:= .T.
	Private lCheckBox2	:= .F.
	Private lCheckBox3	:= .F.

	Private oButton1, oButton2, oButton3, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9, oButton10, oButton11

	Private oOkMark		:= LoadBitmap(GetResources(),"LBOK")
	Private oNoMark		:= LoadBitmap(GetResources(),"LBNO")

	Private oLeg
	Private oVerde		:= LoadBitmap(GetResources(),"BR_VERDE")
	Private oVermelho	:= LoadBitmap(GetResources(),"BR_VERMELHO")

	Private aLinEmpty1   := U_TRE042CP(1,3) //array com linha em branco
	Private aReg		:= {aClone(aLinEmpty1)}

	Private aLinEmpty2   := U_TRE042CP(2,3) //array com linha em branco
	Private aReg2		:= {aClone(aLinEmpty2)}

	Private nCont := nTot := 0

	Private lFiltro		:= .F.

	Private nColOrder	:= 0

	Private cTpFat		:= SuperGetMv("MV_XFPGFAT",.F.,"NP/BOL/RP/CF/FT/CC/CCP/CD/CDP/DP/CT/CTF/NF/VLS/RE/REN/CN")

	// Gianluka Moraes | 13-10-2016 : ComboBox com os tipos de impressões.
	Private cCbTpGer	:= ""
	Private aCbTpGer	:= {"","S-Aglutinado","I-Individual"}

	Private lAltSac		:= SuperGetMv("MV_XALTSAC",.F.,.T.)
	Private lNfAcobert	:= SuperGetMv("MV_XNFACOB",.F.,.F.)

	Private lBtnDiverso := .F.

	Private oBrw 
	Private bBrwLine1	:= U_TRE042CP(1,4) //bloco de atualização da linha
	Private oBrw2 
	Private bBrwLine2	:= U_TRE042CP(2,4) //bloco de atualização da linha

	Static oDlg

	if lNfAcobert //se nota sobre NFCe, não permito alterar sacado
		lAltSac := .F.
	endif

	//controle de acesso botão Diversos
	if lAltSac
		U_TRETA37B("FT006A", "BOTAO DIVERSOS NA ROTINA GERA NF-E CUPOM")
		lBtnDiverso := U_VLACESS2("FT006A", RetCodUsr())
	endif

	aObjects := {}
	aSizeAut := MsAdvSize()

	//Largura, Altura, Modifica largura, Modifica altura
	aAdd(aObjects, {100, 090, .T., .T.}) //Folder
	aAdd(aObjects, {100, 005, .T., .F.}) //Linha horizontal
	aAdd(aObjects, {100, 005, .F., .F.}) //Botao

	aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects, .T. )

	DEFINE MSDIALOG oDlg TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

	//Folder
	If '12' $ cVersao
		@ aPosObj[1,1] - 30, aPosObj[1,2] FOLDER oFolder042 SIZE aPosObj[1,4], aPosObj[1,3] - 10 OF oDlg ITEMS "Filtro","Vendas" COLORS 0, 16777215 PIXEL
	Else
		@ aPosObj[1,1], aPosObj[1,2] FOLDER oFolder042 SIZE aPosObj[1,4], aPosObj[1,3] OF oDlg ITEMS "Filtro","Vendas" COLORS 0, 16777215 PIXEL
	Endif
	oFolder042:nOption := 1
	oFolder042:bChange := {|| HabBotoes()}

	//Pasta Filtro
	@ 005, 005 SAY oSay1 PROMPT "Filial ?" SIZE 030, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 004, 080 MSGET oGet1 VAR cGet1 SIZE 030, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SM0" Picture "@!"
	oSay1:lVisible := .F.
	oGet1:lVisible := .F.

	@ 018, 005 SAY oSay24 PROMPT "CGC/CPF ?" SIZE 030, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 017, 080 MSGET oGet14 VAR cGet14 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SA1NFE"

	@ 031, 005 SAY oSay2 PROMPT "Cliente ?" SIZE 030, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 030, 080 GET oGet2 VAR cGet2 MEMO SIZE 100, 040 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL;
		VALID {||cGet2 := AllTrim(cGet2),cGet2 := Upper(cGet2),.T.} // Adicionado: Felipe Sousa - 16/01/2024 CHAMADO: POSTO-284
	@ 030, 187 BUTTON oButton1 PROMPT "Buscar" SIZE 040, 010 OF oFolder042:aDialogs[1] ACTION FilCli() PIXEL
	@ 045, 187 BUTTON oButton2 PROMPT "Limpar" SIZE 040, 010 OF oFolder042:aDialogs[1] ACTION LimpMemo(@oGet2,@cGet2) PIXEL
	//oGet2:lReadOnly := .T. // Comentado por: Felipe Sousa - 16/01/2024 CHAMADO: POSTO-284

	@ 073, 005 SAY oSay3 PROMPT "Forma de Pagamento ?" SIZE 060, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 072, 080 GET oGet3 VAR cGet3 MEMO SIZE 100, 040 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 072, 187 BUTTON oButton3 PROMPT "Buscar" SIZE 040, 010 OF oFolder042:aDialogs[1] ACTION FilFormaPg() PIXEL
	@ 087, 187 BUTTON oButton4 PROMPT "Limpar" SIZE 040, 010 OF oFolder042:aDialogs[1] ACTION LimpMemo(@oGet3,@cGet3) PIXEL
	oGet3:lReadOnly := .T.

	@ 115, 005 SAY oSay4 PROMPT "Produto ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 114, 080 GET oGet4 VAR cGet4 MEMO SIZE 100, 040 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 114, 187 BUTTON oButton5 PROMPT "Buscar" SIZE 040, 010 OF oFolder042:aDialogs[1] ACTION FilProd() PIXEL
	@ 129, 187 BUTTON oButton6 PROMPT "Limpar" SIZE 040, 010 OF oFolder042:aDialogs[1] ACTION LimpMemo(@oGet4,@cGet4) PIXEL
	@ 144, 187 CHECKBOX oCheckBox3 VAR lCheckBox3 PROMPT "Somente produtos selecionados"  Size 120, 007 PIXEL OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	oGet4:lReadOnly := .T.

	@ 156, 005 SAY oSay5 PROMPT "Emissão de ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 155, 080 MSGET oGet5 VAR dGet5 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	// Gianluka Moraes | 13-10-2016 : Opção de Tipo de Impressão
	@ 156,187 SAY "Tipo Ger. Nf ?" Size 043,007 COLOR CLR_BLACK PIXEL OF oFolder042:aDialogs[1]
	@ 155,230 ComboBox cCbTpGer Items aCbTpGer Size 072,010 PIXEL OF oFolder042:aDialogs[1]

	@ 170, 005 SAY oSay6 PROMPT "Emissão ate ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 169, 080 MSGET oGet6 VAR dGet6 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 183, 005 SAY oSay7 PROMPT "Venda de ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 182, 080 MSGET oGet7 VAR cGet7 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SF2"

	@ 194, 005 SAY oSay8 PROMPT "Venda ate ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 193, 080 MSGET oGet8 VAR cGet8 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SF2"

	@ 207, 005 SAY oSay9 PROMPT "Placa ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 206, 080 MSGET oGet9 VAR cGet9 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "DA3" PICTURE "@!R NNN-9N99"

	@ 005, 245 SAY oSay10 PROMPT "Qtde. de ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 004, 320 MSGET oGet10 VAR nGet10 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL PICTURE "@E 999,999.99999999"

	@ 016, 245 SAY oSay11 PROMPT "Qtde. ate ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 015, 320 MSGET oGet11 VAR nGet11 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL PICTURE "@E 999,999.99999999"

	@ 027, 245 SAY oSay12 PROMPT "Valor de ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 026, 320 MSGET oGet12 VAR nGet12 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL  PICTURE "@E 999,999,999.99"

	@ 038, 245 SAY oSay13 PROMPT "Valor ate ?" SIZE 040, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 037, 320 MSGET oGet13 VAR nGet13 SIZE 060, 010 OF oFolder042:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL  PICTURE "@E 999,999,999.99"

	@ 049, 245 GROUP oSit TO 075, 380 PROMPT "Situações das Vendas" OF oFolder042:aDialogs[1] COLOR 0, 16777215 PIXEL
	@ 061, 255 CHECKBOX oCheckBox1 VAR lCheckBox1 PROMPT "Sem Nota Fiscal"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	@ 061, 310 CHECKBOX oCheckBox2 VAR lCheckBox2 PROMPT "Com Nota Fiscal"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL

	@ 082, 245 SAY oSay15 PROMPT "Dados Adicionais (DANFE) ?" SIZE 120, 007 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 081, 320 GET oGet15 VAR cGet15 MEMO SIZE 100, 040 OF oFolder042:aDialogs[1] COLORS 0, 16777215 PIXEL

	//Pasta Cupons Fiscais
	//Browse Cabeçalho
	If '12' $ cVersao
		oBrw := TWBrowse():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,4] - 10,aPosObj[1,3] - 155,,aCabec,aLarg,oFolder042:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	Else
		oBrw := TWBrowse():New(aPosObj[1,1],aPosObj[1,2],aPosObj[1,4] - 10,aPosObj[1,3] - 145,,aCabec,aLarg,oFolder042:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	Endif
	oBrw:SetArray(aReg)
	oBrw:bChange 		:= {|| BuscaItens()}
	oBrw:blDblClick 	:= {|| MarkReg()}
	oBrw:bHeaderClick 	:= {|oObj,nCol| IIF(nCol ==1 ,MarkAllReg(),),(OrderGrid(oBrw,nCol), nColOrder := nCol)}
	oBrw:bLine := bBrwLine1

	If '12' $ cVersao
		@ (aPosObj[1,3] - 160) + 10 /*aPosObj[1,1] + 113*/, aPosObj[1,2] SAY oSay23 PROMPT "Itens" SIZE 040, 007 OF oFolder042:aDialogs[2] COLORS CLR_BLUE, 16777215 PIXEL
	Else
		@ (aPosObj[1,3] - 145) + 10 /*aPosObj[1,1] + 113*/, aPosObj[1,2] SAY oSay23 PROMPT "Itens" SIZE 040, 007 OF oFolder042:aDialogs[2] COLORS CLR_BLUE, 16777215 PIXEL
	Endif

	//Browse Itens
	If '12' $ cVersao
		oBrw2 := TWBrowse():New(  ( (aPosObj[1,3] - 165) + 10 ) + 15 /*aPosObj[1,1] + 125*/,aPosObj[1,2],aPosObj[1,4] - 10, ( aPosObj[1,3] - ( aPosObj[2,1] - 51) ) + 40  /*aPosObj[1,3] - 170*/,,aCabec2,aLarg2,oFolder042:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	Else
		oBrw2 := TWBrowse():New(  ( (aPosObj[1,3] - 145) + 10 ) + 15 /*aPosObj[1,1] + 125*/,aPosObj[1,2],aPosObj[1,4] - 10, ( aPosObj[1,3] - ( aPosObj[2,1] - 43) ) + 40  /*aPosObj[1,3] - 170*/,,aCabec2,aLarg2,oFolder042:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	Endif
	oBrw2:SetArray(aReg2)
	oBrw2:bLine := bBrwLine2

	// Cria Menu NF s/ CF
	oMenuNf := TMenu():New(0,0,0,0,.T.)
	// Adiciona itens no NF s/ CF
	oIt1Nf := TMenuItem():New(oDlg,"Gerar",,,,{||GeraNFe()},,,,,,,,,.T.)
	oIt2Nf := TMenuItem():New(oDlg,"Estornar",,,,{|| EstNFe() },,,,,,,,,.T.)
	oIt3Nf := TMenuItem():New(oDlg,"NF-e Sefaz",,,,{|| SPEDNFE() },,,,,,,,,.T.)

	//oIt2Nf := TMenuItem():New(oDlg,"Imprimir DANFE",,,,{||ImpNfe()} ,,,,,,,,,.T.) //Danilo: descontinuei, pois nao s

	oMenuNf:Add(oIt1Nf)
	oMenuNf:Add(oIt2Nf)
	oMenuNf:Add(oIt3Nf)

	If '12' $ cVersao
		@ aPosObj[3,1] - 10, aPosObj[3,2] BUTTON oButton7 PROMPT "N. Fiscal" SIZE 050, 010 OF oDlg PIXEL
	Else
		@ aPosObj[3,1] + 5, aPosObj[3,2] BUTTON oButton7 PROMPT "N. Fiscal" SIZE 050, 010 OF oDlg PIXEL
	Endif

	oButton7:SetPopupMenu(oMenuNf)

	If '12' $ cVersao
		@ aPosObj[3,1] - 8, aPosObj[3,2] + 60 SAY oSay21 PROMPT "|" SIZE 020, 007 OF oDlg COLORS CLR_BLUE, 16777215 PIXEL
	Else
		@ aPosObj[3,1] + 7, aPosObj[3,2] + 60 SAY oSay21 PROMPT "|" SIZE 020, 007 OF oDlg COLORS CLR_BLUE, 16777215 PIXEL
	Endif


	If '12' $ cVersao
		@ aPosObj[3,1] - 10, aPosObj[3,2] + 70 BUTTON oButton8 PROMPT "Diversos" SIZE 050, 010 OF oDlg PIXEL
	Else
		@ aPosObj[3,1] + 5, aPosObj[3,2] + 70 BUTTON oButton8 PROMPT "Diversos" SIZE 050, 010 OF oDlg PIXEL
	Endif

	// Cria Menu Diversos
	oMenuDiv 	:= TMenu():New(0,0,0,0,.T.)

	// Adiciona itens no Menu Diversos
	oIt3Div 	:= TMenuItem():New(oDlg,"Observacoes Cliente",,,,{||ObsCliente(aReg[oBrw:nAT][nPosCli],aReg[oBrw:nAT][nPosLoja])},,,,,,,,,.T.)	
	oMenuDiv:Add(oIt3Div)
		
	if lAltSac
		
		//oIt1Div := TMenuItem():New(oDlg,"Trocar Cliente Entidades",,,,{||TrocaCliE()},,,,,,,,,.T.)
		oIt2Div := TMenuItem():New(oDlg,"Trocar Cliente Título",,,,{||TrocaCliT()},,,,,,,,,.T.)

		//oMenuDiv:Add(oIt1Div)
		oMenuDiv:Add(oIt2Div)

	endif

	oButton8:SetPopupMenu(oMenuDiv)

	//Contador e Totalizador
	If '12' $ cVersao
		@ aPosObj[2,1] - 53, aPosObj[2,2] SAY oSay14 PROMPT "Registros selecionados:" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ aPosObj[2,1] - 53, aPosObj[2,2] + 70 SAY oSay15 PROMPT cValToChar(nCont) SIZE 040, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL

		@ aPosObj[2,1] - 53, aPosObj[2,2] + 90 SAY oSay16 PROMPT ", totalizando R$" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ aPosObj[2,1] - 53, aPosObj[2,2] + 130 SAY oSay17 PROMPT nTot SIZE 060, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	Else
		@ aPosObj[2,1] - 43, aPosObj[2,2] SAY oSay14 PROMPT "Registros selecionados:" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ aPosObj[2,1] - 43, aPosObj[2,2] + 70 SAY oSay15 PROMPT cValToChar(nCont) SIZE 040, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL

		@ aPosObj[2,1] - 43, aPosObj[2,2] + 90 SAY oSay16 PROMPT ", totalizando R$" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ aPosObj[2,1] - 43, aPosObj[2,2] + 130 SAY oSay17 PROMPT nTot SIZE 060, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	Endif

	//Legenda
	If '12' $ cVersao
		@ aPosObj[2,1] - 43, aPosObj[2,2] SAY oSay18 PROMPT "Legenda:" SIZE 040, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL

		@ aPosObj[2,1] - 42, aPosObj[2,2] + 35 BITMAP oBmp1 ResName "BR_VERDE" OF oFolder042:aDialogs[2] Size 10,10 NoBorder PIXEL
		@ aPosObj[2,1] - 42, aPosObj[2,2] + 50 SAY oSay19 PROMPT "Sem Nota Fiscal" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL

		@ aPosObj[2,1] - 42, aPosObj[2,2] + 115 BITMAP oBmp2 ResName "BR_VERMELHO" OF oFolder042:aDialogs[2] Size 10,10 NoBorder PIXEL
		@ aPosObj[2,1] - 42, aPosObj[2,2] + 130 SAY oSay20 PROMPT "Com Nota Fiscal" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL
	Else
		@ aPosObj[2,1] - 28, aPosObj[2,2] SAY oSay18 PROMPT "Legenda:" SIZE 040, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL

		@ aPosObj[2,1] - 28, aPosObj[2,2] + 35 BITMAP oBmp1 ResName "BR_VERDE" OF oFolder042:aDialogs[2] Size 10,10 NoBorder PIXEL
		@ aPosObj[2,1] - 28, aPosObj[2,2] + 50 SAY oSay19 PROMPT "Sem Nota Fiscal" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL

		@ aPosObj[2,1] - 28, aPosObj[2,2] + 115 BITMAP oBmp2 ResName "BR_VERMELHO" OF oFolder042:aDialogs[2] Size 10,10 NoBorder PIXEL
		@ aPosObj[2,1] - 28, aPosObj[2,2] + 130 SAY oSay20 PROMPT "Com Nota Fiscal" SIZE 080, 007 OF oFolder042:aDialogs[2] COLORS 0, 16777215 PIXEL
	Endif

	//Linha horizontal
	If '12' $ cVersao
		@ aPosObj[2,1] - 10, aPosObj[2,2] SAY oSay22 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

		@ aPosObj[3,1] - 10, aPosObj[1,4] - 110 BUTTON oButton9 PROMPT "Aplicar filtro" SIZE 060, 010 OF oDlg;
			ACTION {|| Processa({|| Filtro(),"Aguarde"}),lFiltro := .T.,oFolder042:ShowPage(2)} PIXEL
	Else
		@ aPosObj[2,1] + 5, aPosObj[2,2] SAY oSay22 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

		@ aPosObj[3,1] + 5, aPosObj[1,4] - 110 BUTTON oButton9 PROMPT "Aplicar filtro" SIZE 060, 010 OF oDlg;
			ACTION {|| Processa({|| Filtro(),"Aguarde"}),lFiltro := .T.,oFolder042:ShowPage(2)} PIXEL
	Endif

	If '12' $ cVersao
		@ aPosObj[3,1] - 10, aPosObj[1,4] - 90 BUTTON oButton10 PROMPT "Filtro" SIZE 040, 010 OF oDlg ACTION {||oFolder042:ShowPage(1),;
			oButton7:lVisible 	:= .F.,;
			oButton8:lVisible 	:= .F.,;
			oButton9:lVisible 	:= .T.,;
			oSay21:lVisible 	:= .F.,;
			oButton10:lVisible 	:= .F.} PIXEL

		@ aPosObj[3,1] - 10, aPosObj[1,4] - 40 BUTTON oButton11 PROMPT "Fechar" SIZE 040, 010 OF oDlg ACTION oDlg:End() PIXEL
	Else
		@ aPosObj[3,1] + 5, aPosObj[1,4] - 90 BUTTON oButton10 PROMPT "Filtro" SIZE 040, 010 OF oDlg ACTION {||oFolder042:ShowPage(1),;
			oButton7:lVisible 	:= .F.,;
			oButton8:lVisible 	:= .F.,;
			oButton9:lVisible 	:= .T.,;
			oSay21:lVisible 	:= .F.,;
			oButton10:lVisible 	:= .F.} PIXEL

		@ aPosObj[3,1] + 5, aPosObj[1,4] - 40 BUTTON oButton11 PROMPT "Fechar" SIZE 040, 010 OF oDlg ACTION oDlg:End() PIXEL
	Endif

	oButton7:lVisible 	:= .F.
	oButton8:lVisible 	:= .F.
	oButton9:lVisible 	:= .T.
	oSay21:lVisible 	:= .F.
	oButton10:lVisible 	:= .F.

	oGet1:SetFocus() //Get Filial

	ACTIVATE MSDIALOG oDlg CENTERED

Return

//Função gestão dos campos do Grid principal
User Function TRE042CP(nGrid, nOpc, cVarPos)

	Local nPos := 0
	Local xRet
	Local aCabec := {}
	Local aSizes := {}
	Local aLinEmpty := {}
	Local cBrwLin := ""

	Default cVarPos := "0"

	if nGrid == 1 .AND. aCfgCpos1 == Nil
		aadd(aCabec, "") //mark
		aadd(aSizes, 20)
		aadd(aLinEmpty, .F.)
		nPos++

		aadd(aCabec, "") //legenda
		aadd(aSizes, 20)
		aadd(aLinEmpty, LoadBitmap(GetResources(),"BR_VERDE"))
		nPos++
		
		aadd(aCabec, "Filial") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(Len(cFilAnt)))
		nPosFilial := ++nPos

		aadd(aCabec, "Venda") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(9))
		nPosVenda := ++nPos

		aadd(aCabec, "Série") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(3))
		nPosSerie := ++nPos

		aadd(aCabec, "Cliente") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(6))
		nPosCli := ++nPos

		aadd(aCabec, "Loja") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(2))
		nPosLoja := ++nPos

		aadd(aCabec, "Nome") 
		aadd(aSizes, 140)
		aadd(aLinEmpty, Space(40))
		nPosNome := ++nPos

		if SA1->(FieldPos("A1_XOBSFAT")) > 0
			aadd(aCabec, "Obs.Faturamento") 
			aadd(aSizes, 30)
			aadd(aLinEmpty, Space(50))
			nPosObsFat := ++nPos
		endif

		aadd(aCabec, "Valor") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, 0)
		nPosValor := ++nPos

		aadd(aCabec, "Emissão") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, CToD(""))
		nPosEmissao := ++nPos

		aadd(aCabec, "Placa") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(8))
		nPosPlaca := ++nPos

		aadd(aCabec, "Tipo") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(3))
		nPosTipo := ++nPos

		aadd(aCabec, "NF S/Cupom") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(9))
		nPosNFCup := ++nPos

		aadd(aCabec, "R_E_C_N_O_") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, Space(9))
		nPosRecno := ++nPos

		aCfgCpos1 := {aCabec, aSizes, aLinEmpty}

	elseif nGrid == 1
		aCabec 		:= aCfgCpos1[1]
		aSizes 		:= aCfgCpos1[2]
		aLinEmpty 	:= aCfgCpos1[3]
	
	elseif nGrid == 2 .AND. aCfgCpos2 == Nil
		aadd(aCabec, "Produto") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(15))
		nPosProd := ++nPos

		aadd(aCabec, "Descrição") 
		aadd(aSizes, 120)
		aadd(aLinEmpty, Space(30))
		nPosDesc := ++nPos

		aadd(aCabec, "Un") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(2))
		nPosUn := ++nPos

		aadd(aCabec, "Qtde.") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, 0)
		nPosQtd := ++nPos

		aadd(aCabec, "Vlr. unit.") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, 0)
		nPosVlUnit := ++nPos

		aadd(aCabec, "Total Bruto") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, 0)
		nPosTotBr := ++nPos

		aadd(aCabec, "Desconto (R$)") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, 0)
		nPosDescont := ++nPos

		aadd(aCabec, "Total Liq.") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, 0)
		nPosTotLi := ++nPos

	elseif nGrid == 2
		aCabec 		:= aCfgCpos2[1]
		aSizes 		:= aCfgCpos2[2]
		aLinEmpty 	:= aCfgCpos2[3]

	endif

	if nOpc == 1 //retorna lista com nomes dos campos
		xRet := aClone(aCabec)
	elseif  nOpc == 2 //retorna array com largura dos campos
		xRet := aClone(aSizes)
	elseif  nOpc == 3 //retorna linha em branco para o grid
		xRet := aClone(aLinEmpty)
	elseif  nOpc == 4 //retorna bloco de codigo de atualização da linha

		cBrwLin := "{|| {"
		if nGrid == 1
			cBrwLin += "IIF(aReg[oBrw:nAT][1],oOkMark,oNoMark)"
			For nPos := 2 to len(aCabec)
				cBrwLin += ", "+iif(nGrid == 1,"aReg","aReg2")+"[oBrw:nAT]["+cValToChar(nPos)+"]"
			next nPos
		elseif nGrid == 2
			For nPos := 1 to len(aCabec)
				if nPos > 1
					cBrwLin += ", "
				endif
				cBrwLin += "aReg2[oBrw2:nAT]["+cValToChar(nPos)+"]"
			next nPos
		endif
		
		cBrwLin += "}}"

		xRet := &(cBrwLin)
	elseif nOpc == 5 //retorna a posição do parametro 
		xRet := &(cVarPos)
	endif

Return xRet

/**************************/
Static Function HabBotoes()
/**************************/

	If oFolder042:nOption == 1
		oFolder042:SetOption(1)

		oButton7:lVisible 	:= .F.
		oButton8:lVisible 	:= .F.
		oButton9:lVisible 	:= .T.
		oSay21:lVisible 	:= .F.
		oButton10:lVisible 	:= .F.
	Else
		If !lFiltro
			Processa({|| Filtro(),"Aguarde"})
		Else
			lFiltro := .F.
		Endif
	Endif

Return

/***********************/
Static Function Filtro()
/***********************/

	Local cQry 			:= ""
	Local aLinAux		:= {}
	Local cCli 			:= ""
	Local cFormaPg		:= ""
	Local cProd			:= ""
	Local cObsFatCli	:= ""
	Local cSGBD	:= AllTrim(Upper(TcGetDb())) // -- Banco de dados atulizado (Para embientes TOP) 			 	

	If !lCheckBox1 .And. !lCheckBox2
		MsgInfo("Obrigatoriamente uma situação de Cupons Fiscais deve ser selecionada!!","Atenção")
		Return
	Endif

	nCont	:= 0
	nTot	:= 0

	aSize(aReg,0) //Limpa o array

	ProcRegua(0)

	IncProc()

	If Select("QRYCF") > 0
		QRYCF->(dbCloseArea())
	Endif

	cQry := "SELECT SF2.F2_FILIAL,"
	cQry += " SF2.F2_DOC,"
	cQry += " SF2.F2_SERIE,"
	cQry += " SF2.F2_CLIENTE,"
	cQry += " SF2.F2_LOJA,"
	cQry += " SA1.A1_NOME,"
	cQry += " SF2.F2_VALBRUT,"
	cQry += " SF2.F2_EMISSAO,"
	cQry += " SL1.L1_PLACA,"
	If Empty(cGet3) //Forma de Pagamento
		cQry += " '' AS E1_TIPO,"
	else
		cQry += " SE1.E1_TIPO,"
	endif
	cQry += " SF2.F2_NFCUPOM,"
	cQry += " SF2.F2_ESPECIE,"
	cQry += " SF2.R_E_C_N_O_ AS RECNO"
	cQry += " FROM "+RetSqlName("SF2")+" SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" "

	cQry += " 									INNER JOIN "+RetSqlName("SA1")+" SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" 	ON (SF2.F2_CLIENTE = SA1.A1_COD"
	cQry += "																			AND SF2.F2_LOJA = SA1.A1_LOJA"
	cQry += "																			AND SA1.D_E_L_E_T_ <> '*'"
	cQry += " 																			AND SA1.A1_FILIAL = '"+xFilial("SA1")+"')"

	If !Empty(cGet3) //Forma de Pagamento
		cQry += " 									LEFT JOIN "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" 	ON (SF2.F2_SERIE = SE1.E1_PREFIXO"
		cQry += " 										 									AND SF2.F2_DOC = SE1.E1_NUM"
		//cQry += " 										 									AND SF2.F2_CLIENTE	= SE1.E1_CLIENTE"
		//cQry += " 										 									AND SF2.F2_LOJA		= SE1.E1_LOJA"
		cQry += "																			AND SE1.D_E_L_E_T_ <> '*'"
		If !Empty(cGet1) //Filial
			cQry += " 																		AND SE1.E1_FILIAL = '"+cGet1+"'"
		Else
			cQry += " 																		AND SE1.E1_FILIAL = '"+xFilial("SE1")+"'"
		Endif
		cQry += ")"
	endif

	cQry += " 									LEFT JOIN "+ RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" 	ON ( "
	cQry += " 										 									SL1.L1_DOC = SF2.F2_DOC "
	cQry += " 										 									AND SL1.L1_SERIE = SF2.F2_SERIE "
	cQry += " 										 									AND SL1.L1_PDV = SF2.F2_PDV "
	cQry += " 										 									AND SL1.L1_FILIAL = SF2.F2_FILIAL "
	cQry += "  										 									AND SL1.D_E_L_E_T_ <> '*' "
	cQry += " 										 									) "

	cQry += " WHERE SF2.D_E_L_E_T_	<> '*'"
	If !Empty(cGet1) //Filial
		cQry += " AND SF2.F2_FILIAL	= '"+cGet1+"'"
	Else
		cQry += " AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"'"
	Endif
	If lNfAcobert
		cQry += " AND (SF2.F2_ESPECIE	= 'CF   ' OR SF2.F2_ESPECIE	= '' OR SF2.F2_ESPECIE	= 'NFCE ')"
	Else
		cQry += " AND (SF2.F2_ESPECIE	= 'CF   ' OR SF2.F2_ESPECIE	= '')"
	Endif
	cQry += " AND SF2.F2_SERIE NOT LIKE 'IM%'" //Desconsidera cupons fiscais importados
	If !Empty(cGet4) .Or. !Empty(nGet10) .Or. !Empty(nGet11) //Produtos ou Quantidade

		cQry += " AND (SF2.F2_DOC + SF2.F2_SERIE + SF2.F2_CLIENTE + SF2.F2_LOJA	IN (SELECT"
		cQry += "																	DISTINCT SF2_2.F2_DOC + SF2_2.F2_SERIE + SF2_2.F2_CLIENTE + SF2_2.F2_LOJA"
		cQry += "																	FROM "+RetSqlName("SF2")+" SF2_2, "+RetSqlName("SD2")+" SD2"

		cQry += "																	WHERE SF2_2.D_E_L_E_T_	<> '*'"
		cQry += "																	AND SD2.D_E_L_E_T_		<> '*'"

		If !Empty(cGet1) //Filial
			cQry += " 																AND SF2_2.F2_FILIAL		= '"+cGet1+"'"
			cQry += " 																AND SD2.D2_FILIAL		= '"+cGet1+"'"
		Else
			cQry += " 																AND SF2_2.F2_FILIAL		= '"+xFilial("SF2")+"'"
			cQry += " 																AND SD2.D2_FILIAL		= '"+xFilial("SD2")+"'"
		Endif

		cQry += "																	AND SF2_2.F2_DOC		= SD2.D2_DOC"
		cQry += "																	AND SF2_2.F2_SERIE		= SD2.D2_SERIE"
		cQry += "																	AND SF2_2.F2_CLIENTE	= SD2.D2_CLIENTE"
		cQry += "																	AND SF2_2.F2_LOJA		= SD2.D2_LOJA"

		If !Empty(cGet4) //Produtos
			cProd := FormatIN(cGet4,"/")
			cQry += "																AND SD2.D2_COD			IN "+cProd+""
		Endif

		If !Empty(nGet10) //Qtde. De
			cQry += "																AND SD2.D2_QUANT		>= "+cValToChar(nGet10)+""
		Endif

		If !Empty(nGet11) //Qtde. Ate
			cQry += "																AND SD2.D2_QUANT		<= "+cValToChar(nGet11)+""
		Endif

		cQry += "																	)"
		cQry += " OR SF2.F2_DOC + SF2.F2_SERIE + SF2.F2_CLIENTE + SF2.F2_LOJA IS NULL)"
	Endif

	If !Empty(cGet14) //CNPJ/CGC
		cQry += " AND SA1.A1_CGC = '"+cGet14+"'"
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

	If !Empty(cGet7) //Cupom - De
		cQry += " AND SF2.F2_DOC 	>= '"+cGet7+"'"
	Endif

	If !Empty(cGet8) //Cupom - Ate
		cQry += " AND SF2.F2_DOC 	<= '"+cGet8+"'"
	Endif

	If !Empty(cGet9) //Placa
		cQry += " AND SL1.L1_PLACA = '"+StrTran(cGet9,"-","")+"'"
	Endif

	If !Empty(nGet12) //Valor - De
		cQry += " AND SF2.F2_VALBRUT >= '"+cValToChar(nGet12)+"'"
	Endif

	If !Empty(nGet13) //Valor - Ate
		cQry += " AND SF2.F2_VALBRUT <= '"+cValToChar(nGet13)+"'"
	Endif

	If lCheckBox1 .And. !lCheckBox2
		cQry += " AND SF2.F2_NFCUPOM = ''"
	ElseIf !lCheckBox1 .And. lCheckBox2
		cQry += " AND SF2.F2_NFCUPOM <> ''"
	Endif

	cQry += " ORDER BY 1,2,3,4,5"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETA042.txt",cQry)
	TcQuery cQry NEW Alias "QRYCF"

	If QRYCF->(!EOF())

		While QRYCF->(!EOF())

			IncProc()

			If !Empty(cGet4) .And. lCheckBox3 //Obriga os itens dos Cupons serem exatamente os produtos selecionados

				If !SoProd(QRYCF->F2_FILIAL,QRYCF->F2_DOC,QRYCF->F2_SERIE,QRYCF->F2_CLIENTE,QRYCF->F2_LOJA)
					QRYCF->(dbSkip())
					Loop
				Endif
			Endif

			//Desconsidera caso conste numa Nota de Devolução
			If PossuiDev(QRYCF->F2_FILIAL,QRYCF->F2_DOC,QRYCF->F2_SERIE,QRYCF->F2_CLIENTE,QRYCF->F2_LOJA)
				QRYCF->(dbSkip())
				Loop
			Endif

			//Legenda
			If Empty(QRYCF->F2_NFCUPOM)
				oLeg := oVerde //Sem Nota Fiscal
			Else
				oLeg := oVermelho //Com Nota Fiscal
			Endif

			aLinAux := aClone(aLinEmpty1)
			aLinAux[2] := oLeg
			aLinAux[nPosFilial] := QRYCF->F2_FILIAL
			aLinAux[nPosVenda] := QRYCF->F2_DOC
			aLinAux[nPosSerie] := QRYCF->F2_SERIE
			aLinAux[nPosCli] := QRYCF->F2_CLIENTE
			aLinAux[nPosLoja] := QRYCF->F2_LOJA
			aLinAux[nPosNome] := AllTrim(QRYCF->A1_NOME)
			aLinAux[nPosValor] := Transform(QRYCF->F2_VALBRUT,"@E 9,999,999,999,999.99")
			aLinAux[nPosEmissao] := DToC(SToD(QRYCF->F2_EMISSAO))
			aLinAux[nPosPlaca] := Transform(QRYCF->L1_PLACA,"@!R NNN-9N99")
			aLinAux[nPosTipo] := QRYCF->E1_TIPO
			aLinAux[nPosNFCup] := QRYCF->F2_NFCUPOM
			aLinAux[nPosRecno] := QRYCF->RECNO
			if SA1->(FieldPos("A1_XOBSFAT")) > 0
				cObsFatCli := Alltrim(StrTran(Posicione("SA1",1,xFilial("SA1",QRYCF->F2_FILIAL)+QRYCF->F2_CLIENTE+QRYCF->F2_LOJA,"A1_XOBSFAT"),Chr(13)+Chr(10)," "))
				aLinAux[nPosObsFat] := SubStr(cObsFatCli,1,30) + iif(len(cObsFatCli)>30,"...","")
			endif

			AAdd(aReg, aLinAux)

			QRYCF->(dbSkip())
		EndDo
	Else
		aSize(aReg,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg := nil
		aReg := {}
		aadd(aReg, aClone(aLinEmpty1))
	Endif

	If Len(aReg) == 0
		aSize(aReg,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg := nil
		aReg := {}
		aadd(aReg, aClone(aLinEmpty1))
	Endif

	oBrw:SetArray(aReg)
	oBrw:bLine := bBrwLine1

	oBrw:nAt := 1
	oBrw:Refresh()

	oSay15:Refresh() //Contador
	oSay17:Refresh() //Totalizador

	If Select("QRYCF") > 0
		QRYCF->(dbCloseArea())
	Endif

	//Atualiza os itens conforme o Cupom posicionado
	BuscaItens()

	oButton7:lVisible 	:= .T.	
	If lAltSac .OR. SA1->(FieldPos("A1_XOBSFAT")) > 0 //botão Diversos
		oButton8:lVisible 	:= .T. //lBtnDiverso
	Endif
	oButton9:lVisible 	:= .F.
	oSay21:lVisible 	:= .T.
	oButton10:lVisible 	:= .T.

	oBrw:SetFocus()

Return

Static Function BuscaItens()

	Local aLinAux		:= {}
	Local cQry := ""

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
	cQry += " AND SD2.D2_FILIAL		= '"+aReg[oBrw:nAT][nPosFilial]+"'"
	cQry += " AND SB1.B1_FILIAL		= '"+xFilial("SB1")+"'"
	cQry += " AND SD2.D2_COD		= SB1.B1_COD"
	cQry += " AND SD2.D2_DOC		= '"+aReg[oBrw:nAT][nPosVenda]+"'"
	cQry += " AND SD2.D2_SERIE		= '"+aReg[oBrw:nAT][nPosSerie]+"'"
	cQry += " AND SD2.D2_CLIENTE	= '"+aReg[oBrw:nAT][nPosCli]+"'"
	cQry += " AND SD2.D2_LOJA		= '"+aReg[oBrw:nAT][nPosLoja]+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETA042_2.txt",cQry)
	TcQuery cQry NEW Alias "QRYITENS"

	If QRYITENS->(!EOF())

		While QRYITENS->(!EOF())

			IncProc()

			aLinAux := aClone(aLinEmpty2)
			aLinAux[nPosProd] := QRYITENS->D2_COD
			aLinAux[nPosDesc] := QRYITENS->B1_DESC
			aLinAux[nPosUn] := QRYITENS->D2_UM
			aLinAux[nPosQtd] := Transform(QRYITENS->D2_QUANT,"@E 999,999.99999999")
			aLinAux[nPosVlUnit] := Transform(QRYITENS->D2_PRUNIT,"@E 99,999,999.99999999")
			//aLinAux[nPosTotBr] := Transform(A410Arred(QRYITENS->D2_QUANT * QRYITENS->D2_PRUNIT,"L2_VLRITEM"),"@E 999,999,999.99")
			aLinAux[nPosTotBr] := Transform(QRYITENS->D2_TOTAL+QRYITENS->D2_DESCON,"@E 999,999,999.99")
			aLinAux[nPosDescont] := Transform(QRYITENS->D2_DESCON,"@E 99,999,999.99999999")
			aLinAux[nPosTotLi] := Transform(QRYITENS->D2_TOTAL,"@E 999,999,999.99")

			AAdd(aReg2, aLinAux)

			QRYITENS->(dbSkip())
		EndDo
	Else
		aSize(aReg2,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg2 := nil
		aReg2 := {}
		aadd(aReg2, aClone(aLinEmpty2))
		oBrw2:nAT := 1
	Endif

	If Len(aReg2) == 0
		aSize(aReg2,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg2 := nil
		aReg2 := {}
		aadd(aReg2, aClone(aLinEmpty2))
		oBrw2:nAT := 1
	Endif

	oBrw2:SetArray(aReg2)
	oBrw2:bLine := bBrwLine2

	oBrw2:Refresh()

	If Select("QRYITENS") > 0
		QRYITENS->(dbCloseArea())
	Endif

Return

/***********************/
Static Function FilCli()
/***********************/

//																	cTitulo, 	cAlias,cColunas, 					  cOrdem,					cCond			,cInf
	MsgRun("Selecionando registros...","Aguarde",{|| cGet2 := U_UMultSel("Clientes","SA1","A1_COD,A1_LOJA,A1_NOME,A1_CGC","A1_NOME,A1_COD,A1_LOJA","A1_MSBLQL = '2'",cGet2)})
	oGet2:Refresh()

Return

/***************************/
Static Function FilFormaPg()
/***************************/

//																	cTitulo, 			  cAlias,cColunas	  		,cOrdem     ,cCond				,cInf
	MsgRun("Selecionando registros...","Aguarde",{|| cGet3 := U_UMultSel("Formas de Pagamento","SX5","X5_CHAVE,X5_DESCRI","X5_DESCRI","X5_TABELA = '24'",cGet3)})
	oGet3:Refresh()

Return

/************************/
Static Function FilProd()
/************************/

//																	cTitulo,    cAlias,cColunas	  	 ,cOrdem    ,cCond	  		  ,cInf
	MsgRun("Selecionando registros...","Aguarde",{|| cGet4 := U_UMultSel("Produtos","SB1","B1_COD,B1_DESC","B1_DESC","B1_MSBLQL <> '1'",cGet4)})
	oGet4:Refresh()

Return

/************************/
Static Function MarkReg()
/************************/

	if nPosObsFat<> Nil .AND. nPosObsFat > 0 .AND. oBrw:nColPos == nPosObsFat .AND. !empty(aReg[oBrw:nAT][nPosObsFat])
		ObsCliente(aReg[oBrw:nAT][nPosCli],aReg[oBrw:nAT][nPosLoja])
		Return
	endif
	
	If !Empty(aReg[oBrw:nAT][nPosFilial]) //Filial/Registro válido
		If aReg[oBrw:nAT][1]
			aReg[oBrw:nAT][1] := .F.
			nCont--
			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",",".")) > 0
				nTot -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",",".")) //Valor
			Endif
		Else
			aReg[oBrw:nAT][1] := .T.
			nCont++
			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",",".")) > 0
				nTot += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",",".")) //Valor
			Endif
		Endif
	Endif

	oBrw:Refresh()
	oSay15:Refresh()
	oSay17:Refresh()

Return

/***************************/
Static Function MarkAllReg()
/***************************/

	Local nI

	nCont	:= 0
	nTot  	:= 0

	If !Empty(aReg[oBrw:nAT][nPosFilial]) //Filial/Registro válido
		If aReg[oBrw:nAT][1]
			For nI := 1 To Len(aReg)
				aReg[nI][1] := .F.
			Next
		Else
			For nI := 1 To Len(aReg)
				aReg[nI][1] := .T.
				nCont++

				If Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",",".")) > 0
					nTot += Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",",".")) //Valor
				Endif
			Next
		Endif
	Endif

	oBrw:Refresh()
	oSay15:Refresh()
	oSay17:Refresh()

Return

/************************/
Static Function GeraNFe()
/************************/

	Local nI
	Local nCont			:= 0
	Local nContAux		:= 0
	Local lAux 			:= .T.
	Local cNfsGeradas	:= " "

	Local lMostraMsg	:= .T.
	Local aCupons       := {}

	Local lAltFil		:= .F.
	Local cFilBkp		:= cFilAnt

	Local cTpGerNf		:= IIF(!Empty(AllTrim(cCbTpGer)),Substr(cCbTpGer,1,1),"")

	Local cCli			:= ""
	Local cLojaCli		:= ""
	Local lCliDif		:= .F.
	Local lNACliPad		:= SuperGetMV("TP_XNFACPA",,.T.) //define se poderá emitir nota sobre cupom de consumidor padrao

	Local lDecio := SuperGetMv("MV_XDECIO",,.F.) //Parametro para tratamentos específicos do Decio (temporario)
	Local lDecioCliPad := .F.
	Local cCliPad		:= SuperGetMV("MV_CLIPAD",,"")								// Cliente padrão
	Local cLojaPad		:= SuperGetMV("MV_LOJAPAD",,"")								// Loja do cliente padrão
	Local cBkpCli		:= ""
	Local cBkpLoja		:= ""

	If !Empty(cGet1) .And. cGet1 <> cFilAnt
		cFilBkp	:= cFilAnt
		cFilAnt	:= cGet1
		lAltFil	:= .T.
	Endif

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.

			If Empty(cCli)

				cCli 		:= aReg[nI][nPosCli]
				cLojaCli 	:= aReg[nI][nPosLoja]
			Else
				If cCli <> aReg[nI][nPosCli] .Or. cLojaCli <> aReg[nI][nPosLoja]
					lCliDif := .T.
				Endif
			Endif

			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado!!","Atenção")
		lAux := .F.
	ElseIf lCliDif
		MsgInfo("Em caso de Geração de Nota sobre Cupons Fiscais, os cupons obrigatoriamente devem pertencer a um mesmo Cliente e Loja!!","Atenção")
		lAux := .F.
	Endif

	If lAux

		If MsgYesNo("Haverá a geração de N. Fiscal para os registros selecionados, deseja continuar?")
			SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			For nI := 1 To Len(aReg)

				If aReg[nI][1] == .T.

					If lAux .AND. !ValCliNf(AllTrim(aReg[nI][nPosCli]),AllTrim(aReg[nI][nPosLoja]))
						if lNACliPad
							If nContAux == 0
								aRet := GetCliNfCup()
								if !empty(aRet[1]+aRet[2])
									cCli := aRet[1]
									cLojaCli := aRet[2]
									lDecioCliPad := .T.
								else
									MsgInfo("Cliente de destino <"+AllTrim(aReg[nI][nPosCli])+">, referente a venda <"+AllTrim(aReg[nI][nPosVenda])+">, não pode ser igual a um Cliente padrão!!","Atenção")
									lAux := .F.
									EXIT
								endif
							endif
						else
							MsgInfo("Cliente de destino <"+AllTrim(aReg[nI][nPosCli])+">, referente a venda <"+AllTrim(aReg[nI][nPosVenda])+">, não pode ser igual a um Cliente padrão!!","Atenção")
							lAux := .F.
							EXIT
						endif
					EndIf
					If lAux .AND. !Empty(aReg[nI][nPosNFCup]) //Possui Nf s/ Cf
						MsgInfo("A venda "+AllTrim(aReg[nI][nPosVenda])+" possui Nota Fiscal relacionada, operação não permitida!!","Atenção")
						lAux := .F.
						EXIT
					Endif

					if lAux
						
						//MUDO O CLIENTE PADRAO DA SL1
						if lDecio .AND. lDecioCliPad
							if aReg[nI][nPosCli]+aReg[nI][nPosLoja] <> cCliPad+cLojaPad
								if SL1->(DbSeek(xFilial("SL1")+aReg[nI][nPosSerie]+aReg[nI][nPosVenda]))
									cBkpCli	:= SL1->L1_CLIENTE
									cBkpLoja := SL1->L1_LOJA
									If RecLock('SL1',.F.)
										SL1->L1_CLIENTE := cCliPad
										SL1->L1_LOJA := cLojaPad
										SL1->(MsUnlock())
									EndIf
								endif
							endif
						endif

						//If nCont == 1 //Somente um cupom, emite mensagem
						//Filial							Tipo	   Prefixo	  Número		Cliente		Loja     PDV    MsgAdic
						//	Processa({|| U_TRETE036(IIF(!Empty(cGet1),cGet1,cFilAnt),aReg[nI][12],aReg[nI][5],aReg[nI][4],aReg[nI][6],aReg[nI][7],.F.,.T.,,,cGet15,cTpGerNf),"Aguarde"})

						//Else             //Numero    //Prefixo   //Cliente   //Loja
						Aadd(aCupons,{aReg[nI][nPosVenda],aReg[nI][nPosSerie],aReg[nI][nPosCli],aReg[nI][nPosLoja]})
						//Endif

						nContAux++
					Endif
				Endif
			Next nI

			if lAux
				If Len(aCupons) > 0 					//Filial		Tipo Prefixo Número	Cliente	Loja  PDV  			  MsgAdic
					//if empty(cTpGerNf) .or. cTpGerNf == "S" //aglutinado
					lMostraMsg := .F. //nao mostrar mensagem na rotina TRETE036
					nContAux := 0
					//endif
					Processa({|| U_TRETE036(IIF(!Empty(cGet1),cGet1,cFilAnt),"","","",cCli,cLojaCli,.F.,lMostraMsg,aCupons,,cGet15,cTpGerNf,@nContAux,@cNfsGeradas),"Aguarde"})

					//RESTAURO O CLIENTE 
					if lDecio .AND. lDecioCliPad .AND. !empty(cBkpCli)
						SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
						For nI := 1 To Len(aReg)
							If aReg[nI][1] == .T.
								if SL1->(DbSeek(xFilial("SL1")+aReg[nI][nPosSerie]+aReg[nI][nPosVenda]))
									If RecLock('SL1',.F.)
										SL1->L1_CLIENTE := cBkpCli
										SL1->L1_LOJA := cBkpLoja
										SL1->(MsUnlock())
									EndIf
								endif
							Endif
						Next nI
					endif
				EndIf

				//Aviso ao usuário
				//if empty(cTpGerNf) .or. cTpGerNf == "S" //aglutinado
				If nContAux == 0
					MsgInfo("Nenhuma Nota Fiscal processada!!","Atenção")
				Else
					MsgInfo("Nota(s) Fiscal(is) processada(s) com sucesso!" + chr(13)+chr(10) + "Nota(s): "+cNfsGeradas,"Atenção")
				Endif
				//Endif

				Processa({|| Filtro(),"Aguarde"})
			endif
		Endif
	Endif

//Se houve alteração da filial, retorna a filial logada
	If lAltFil
		cFilAnt := cFilBkp
	Endif

Return

/***********************/
Static Function ImpNFe()
/***********************/

	Local nI
	Local nCont		:= 0
	Local lAux 		:= .T.

	Local oSay1, oSay2
	Local oButton1, oButton2

	Local oQtdVia

	Private _nQtdVia	:= 1

	Static oDlgImpNfe

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado!!","Atenção")
		lAux := .F.
	Endif

	If lAux

		DEFINE MSDIALOG oDlgImpNfe TITLE "Quantidade de vias" From 000,000 TO 120,212 PIXEL

		@ 010, 010 SAY oSay1 PROMPT "Qtde. Vias" SIZE 080, 007 OF oDlgImpNfe COLORS 0, 16777215 PIXEL
		@ 010, 055 MSGET oQtdVia VAR _nQtdVia SIZE 030, 010 OF oDlgImpNfe COLORS 0, 16777215 Valid(ValQtdVia(_nQtdVia)) PIXEL Picture "@E 9"

		//Linha horizontal
		@ 030, 010 SAY oSay2 PROMPT Repl("_",80) SIZE 80, 007 OF oDlgImpNfe COLORS CLR_GRAY, 16777215 PIXEL

		@ 041, 010 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgImpNfe ACTION ConfImpNfe() PIXEL
		@ 041, 060 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgImpNfe ACTION oDlgImpNfe:End() PIXEL

		ACTIVATE MSDIALOG oDlgImpNfe CENTERED

	Endif

Return

/**********************************/
Static Function ValQtdVia(_nQtdVia)
/**********************************/

	Local lRet := .T.

	If _nQtdVia < 1
		MsgInfo("A Quantidade de vias não pode ser inferior a 1 (uma) via!!","Atenção")
		lRet := .F.
	Endif

Return lRet

/***************************/
Static Function ConfImpNfe()
/***************************/

	Local nI, nJ

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.

			For nJ := 1 To _nQtdVia
				//Filial	Tipo		Número		Cliente		Loja
				//Processa({|| U_TRETE037(aReg[nI][3],aReg[nI][12],aReg[nI][4],aReg[nI][6],aReg[nI][7]),"Aguarde"})
				U_TRETE037(aReg[nI][nPosFilial],aReg[nI][nPosTipo],aReg[nI][nPosVenda],aReg[nI][nPosCli],aReg[nI][nPosLoja])
			Next nJ
		Endif
	Next nI

	oDlgImpNfe:End()

	MsgInfo("Processamento finalizado!!","Atenção")

	Processa({|| Filtro(),"Aguarde"})

Return

/********************************/
Static Function TrocaCliE(nRecno)
/********************************/

	Local nI
	Local nCont		:= 0
	Local lAux 		:= .T.
	Local dBkDtBase := dDataBase

	//Local aRecno	:= {}

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado!!","Atenção")
		lAux := .F.
//ElseIf nCont > 1
//	MsgInfo("A Troca de Cliente em todas Entidades é executada para uma venda de cada vez!!","Atenção")
//	lAux := .F.
	Endif

	If lAux

		If nCont == 1
			//For nI := 1 To Len(aReg)

			//	If aReg[nI][1] == .T.
					//Filial	Número		Cliente		Loja       Emissão
					//U_RPOS012(aReg[nI][3],aReg[nI][4],aReg[nI][6],aReg[nI][7],CToD(aReg[nI][10]))
					MsgInfo("Função não disponibilizada para o novo template de posto!!","Atenção")
			//	Endif
			//Next nI
		Else
			//For nI := 1 To Len(aReg)
			//	If aReg[nI][1] == .T.
			//		Aadd( aRecno, aReg[nI][14] )
			//	Endif
			//Next nI
			//Filial	Número	Cliente		Loja       Emissão           Recno
			//U_RPOS012(aReg[1][3],aReg[1][4],aReg[1][6],aReg[1][7],CToD(aReg[1][10]),aRecno)
			MsgInfo("Função não disponibilizada para o novo template de posto!!","Atenção")
		EndIf


		Processa({|| Filtro(),"Aguarde"})
	Endif

	dDataBase := dBkDtBase

Return

/********************************/
Static Function TrocaCliT(nRecno)
/********************************/

	Local nI
	Local nCont		:= 0
	Local lAux 		:= .T.
	Local dBkDtBase := dDataBase

	For nI := 1 To Len(aReg)

		If aReg[nI][1] == .T.
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado!!","Atenção")
		lAux := .F.
	ElseIf nCont > 1
		MsgInfo("A Troca de Cliente no Título é executada para uma venda de cada vez!!","Atenção")
		lAux := .F.
	Endif

	If lAux

		For nI := 1 To Len(aReg)

			If aReg[nI][1] == .T.
				//Filial	Emissão				Número		Cliente		Loja
				U_TRETA043(aReg[nI][nPosFilial],CToD(aReg[nI][nPosEmissao]),aReg[nI][nPosVenda],aReg[nI][nPosCli],aReg[nI][nPosLoja])
			Endif
		Next nI

		Processa({|| Filtro(),"Aguarde"})
	Endif

	dDataBase := dBkDtBase

Return

/*************************************/
Static Function OrderGrid(oObj,nColum)
/*************************************/

	If nColum <> 1 .And. nColum <> 2 .And. nColum <> 14 //Flag seleção e Legenda e R_E_C_N_O_

		//Valor - N
		If nColum == 9

			ASort(aReg,,,{|x,y| (StrZero(INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")))) * 1000) + x[7] ) < ( StrZero(INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")))) * 1000) + y[7])})

			//Filial ou Nro. Cupom ou Série ou Cliente ou Loja ou Nome ou Placa ou Tipo ou NF s/ Cupom - C
		ElseIf nColum == 3 .Or. nColum == 4 .Or. nColum == 5 .Or. nColum == 6 .Or. nColum == 7 .Or. nColum == 8 .Or. nColum == 11 .Or. nColum == 12 .Or.;
				nColum == 13

			ASort(aReg,,,{|x,y| x[nColum] + x[7] < y[nColum] + y[7]})

			//Dt. Emissão
		ElseIf nColum == 10

			ASort(aReg,,,{|x,y| DToS(CToD(x[nColum])) + x[7] < DToS(CToD(y[nColum])) + y[7]})
		Endif

		oBrw:SetArray(aReg)
		oBrw:bLine := bBrwLine1

		oBrw:Refresh()
	Endif

Return

/************************************/
User Function TR042VCN(cCli,cLojaCli)
Return ValCliNf(cCli,cLojaCli)
Static Function ValCliNf(cCli,cLojaCli)
/************************************/

	Local lRet    	:= .T.
	Local aArea		:= GetArea()
	Local aAreaSA1	:= SA1->(GetArea())
	Local aPars		:= FWAllFilial(cEmpAnt,,,.F.) //Retorna as filiais para o grupo de empresas
	Local nI		:= 0
	Local bGetMvFil	:= {|cPar, cFil| Alltrim(SuperGetMv(cPar,.F.,,cFil)) }

	if empty(cCli+cLojaCli)
		lRet := .F.
	endif

	if lRet
		For nI := 1 To Len(aPars)
			//If cCli + cLojaCli == AllTrim(SuperGetMv("MV_CLIPAD",.F.,,aPars[nI])) + AllTrim(SuperGetMv("MV_LOJAPAD",.F.,,aPars[nI]))
			If cCli + cLojaCli == Eval(bGetMvFil, "MV_CLIPAD", aPars[nI]) + Eval(bGetMvFil, "MV_LOJAPAD", aPars[nI])
				lRet := .F.
			EndIf
		Next nI
	endif

	if lRet
		SA1->(DbSetOrder(1))
		lRet := SA1->(DbSeek(xFilial("SA1")+cCli+cLojaCli))
	endif

	RestArea(aAreaSA1)
	RestArea(aArea)

Return lRet

/**********************************************************/
Static Function SoProd(_cFil,_cDoc,_cSerie,_cCli,_cLojaCli)
/**********************************************************/

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
//MemoWrite("c:\temp\TRETA042.txt",cQry)
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

/***********************************************************/
//SubFunção - LimpMemo
/***********************************************************/
Static Function LimpMemo(_oObjeto,_cInf)

	_cInf := Space(200)
	_oObjeto:Refresh()

Return

/*****************************************************/
Static Function PossuiDev(cFil,cTit,cPref,cCli,cLojaCli)
/*****************************************************/

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYDEV") > 0
		QRYDEV->(dbCloseArea())
	Endif

	cQry := "SELECT SD1.D1_DOC"
	cQry += " FROM "+RetSqlName("SD1")+" SD1"
	cQry += " WHERE SD1.D_E_L_E_T_	<> '*'"

	If cFil == Nil
		cQry += " AND SD1.D1_FILIAL 	= '"+xFilial("SD1")+"'"
	Else
		cQry += " AND SD1.D1_FILIAL 	= '"+cFil+"'"
	Endif

	cQry += " AND SD1.D1_TIPO		= 'D'" //Devolução
	cQry += " AND SD1.D1_NFORI		= '"+cTit+"'"
	cQry += " AND SD1.D1_SERIORI	= '"+cPref+"'"
	cQry += " AND SD1.D1_FORNECE	= '"+cCli+"'"
	cQry += " AND SD1.D1_LOJA		= '"+cLojaCli+"'"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE001_DEV.txt",cQry)
	TcQuery cQry NEW Alias "QRYDEV"

	If QRYDEV->(!EOF())
		lRet := .T.
	Endif

	If Select("QRYDEV") > 0
		QRYDEV->(dbCloseArea())
	Endif

Return lRet


Static Function GetCliNfCup()

	Local lOk := .F.
	Local aCliRet := {Space(TamSX3("A1_COD")[1]),Space(TamSX3("A1_LOJA")[1])}
	Local oButton1
	Local oButton2
	Private oDlgCliNf

	DEFINE MSDIALOG oDlgCliNf TITLE "Cliente Destino" FROM 000, 000  TO 200, 350 COLORS 0, 16777215 PIXEL

	@ 012, 011 SAY oSay1 PROMPT "Cupom(s) de origem emitido(s) para Consumidor Padrão! Escolha um cliente destino para emissão da nota" SIZE 150, 016 OF oDlgCliNf COLORS 0, 16777215 PIXEL

	@ 040, 012 SAY oSay2 PROMPT "Cliente" SIZE 025, 007 OF oDlgCliNf COLORS 0, 16777215 PIXEL
	@ 048, 012 MSGET oCliNF VAR aCliRet[1] SIZE 046, 010 OF oDlgCliNf COLORS 0, 16777215 F3 "SA1" PIXEL HASBUTTON

	@ 040, 078 SAY oSay3 PROMPT "Loja" SIZE 025, 007 OF oDlgCliNf COLORS 0, 16777215 PIXEL
	@ 048, 078 MSGET oLojaNF VAR aCliRet[2] SIZE 023, 010 OF oDlgCliNf COLORS 0, 16777215 PIXEL

	@ 073, 123 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 012 OF oDlgCliNf PIXEL ACTION iif(lOk:=ValCliNf(aCliRet[1],aCliRet[2]), oDlgCliNf:end(),MsgInfo("Selecione um cliente valido!","Atenção"))
	@ 073, 081 BUTTON oButton2 PROMPT "Cancelar" SIZE 037, 012 OF oDlgCliNf PIXEL ACTION (oDlgCliNf:end())

	ACTIVATE MSDIALOG oDlgCliNf CENTERED

	if !lOk //se nao ta ok, retorno vazio para abortar rotina
		aCliRet := {Space(TamSX3("A1_COD")[1]),Space(TamSX3("A1_LOJA")[1])}
	endif

Return aCliRet

//FUNCAO PARA ESTORNO
Static Function EstNfe()

	Local nI
	Local nPosSel := 0
	Local cDocStrNf, cSerStrNf
	Local nCont := 0
	Local aNFS			:= {} //Array com as notas fiscal para estorno

	For nI := 1 To Len(aReg)
		If aReg[nI][1] == .T.
			nCont++
			nPosSel := nI
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado!!","Atenção")
		Return .F.
	ElseIf nCont > 1
		MsgInfo("Selecione apenas um registro para realizar o estorno!!","Atenção")
		Return .F.
	Elseif Empty(aReg[nPosSel][nPosNFCup])
		MsgInfo("Não há nota fiscal emtida sobre o cupom selecionado!","Atenção")
		Return .F.
	Endif

	cSerStrNf := SubStr(aReg[nPosSel][nPosNFCup],1,3)
	cDocStrNf := SubStr(aReg[nPosSel][nPosNFCup],4)

	SF2->(DbSetOrder(1))//"F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO"
	If SF2->( DbSeek(xFilial("SF2") + cDocStrNf + cSerStrNf) )
		//If (SF2->F2_FIMP$"TS") //Verifica apenas a especie como SPED e notas que foram transmitidas ou impresso o DANFE
		//	MsgInfo("Nao foi possivel excluir a nota fiscal "+aReg[nPosSel][nPosNFCup]+", pois já está transmitida ao SEFAZ.","Atenção")
		//	Return .F.
		//EndIf
		if !ValidaPrazo()
			Return .F.
		endif
	Else
		MsgInfo("Nota fiscal "+aReg[nPosSel][nPosNFCup]+" não encontrada para estorno!","Atenção")
		Return .F.
	Endif

	If MsgYesNo("Haverá o estorno do registro selecionado, deseja continuar?")

		AAdd(aNFS,{SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_CLIENTE,SF2->F2_LOJA}) //Documento,Serie,Cliente e Loja

		//chama rotina de estorno em JOB
		If StartJOB("U_TRE042ES",GetEnvServer(), .T./*lWait*/, cEmpAnt, cFilAnt, aNFS)
			MsgInfo("Estorno processado com sucesso!!","Atenção")
		EndIf

		Processa({|| Filtro(),"Aguarde"})

	endif

Return

User Function TR042VLP()
Return ValidaPrazo()
Static Function ValidaPrazo()

	Local lRet := .T.
	Local nSpedExc 		:= SuperGetMV("MV_SPEDEXC",,72)			// Indica a quantidade de horas q a NFe pode ser cancelada
	Local cHoraRMT		:= SuperGetMV("MV_HORARMT",,"1")		// 1 - Considera a hora do SmartCient | 2 - Considera a hora do Servidor | 3 - Fuso hor?io da filial corrente
	Local cHoraUF 		:= FwTimeUF(SM0->M0_ESTENT)[2]
	Local dHVeraoI:= SuperGetMV("MV_HVERAOI",.F.,CTOD('  /  /    '))
	Local dHVeraoF:= SuperGetMV("MV_HVERAOF",.F.,CTOD('  /  /    '))
	Local lHverao := .F.
	Local dDtdigit, nHoras

	/* Verifica se eh uma NF-e, pois neste caso deve respeitar o MV_SPEDEXC, que indica qual o prazo max para cancelamento */
	If "SPED" $ SF2->F2_ESPECIE .AND. SF2->F2_FIMP $ "TS" 

		If cHoraRMT == "1" // Horario do SmartClient
			cHoraUF := SubStr(GetRmtTime(),1,8)
		ElseIf cHoraRMT == "3" // Fuso hor?io do estado

			//-- TBC-GO SUGESTAO MELHORIA Verifica se é horário de verão (compatibilidade com os demais modulos)
			If !Empty(dHVeraoI) .And. !Empty(dHVeraoF) .And. dDataBase >= dHVeraoI .And. dDataBase <= dHVeraoF
				lHverao := .T.
			EndIf

			cHoraUF := FwTimeUF(SM0->M0_ESTENT,,lHVerao)[2]
		Else // 2- Default - Horario do Server
			cHoraUF := SubStr(Time(),1,8)
		EndIf

		If !Empty(SF2->F2_DAUTNFE) .AND. !Empty(SF2->F2_HAUTNFE)
			dDtdigit := SF2->F2_DAUTNFE
			nHoras   := SubtHoras( dDtdigit, SF2->F2_HAUTNFE, dDATABASE, SubStr(cHoraUF,1,2) + ":" + SubStr(cHoraUF,4,2) )
		Else
			dDtdigit := SF2->F2_EMISSAO
			nHoras   := SubtHoras( dDtdigit, SF2->F2_HORA, dDATABASE, SubStr(cHoraUF,1,2) + ":" + SubStr(cHoraUF,4,2) )
		Endif	

		If nHoras > nSpedExc 
			MsgAlert("[" + SF2->F2_FILIAL + "/" + SF2->F2_DOC+SF2->F2_SERIE + "] Não foi possivel excluir a nota, pois o prazo para o cancelamento do documento de saída é de " + cValToChar(nSpedExc) + " horas. Conforme configurado no parametro MV_SPEDEXC.")
			lRet := .F.	
		EndIf
	endif

Return lRet

/*/{Protheus.doc} ObsCliente
Funcao para exibir as observacoes do cliente
@type function
@version 1.0
@author g.sampaio
@since 02/10/2023
@param cCodCliente, character, Codigo do Cliente
@param cCodLoja, character, Codigo Loja
/*/
Static Function ObsCliente(cCodCliente, cCodLoja)

	Local aArea			:= GetArea()
	Local aAreaSA1		:= SA1->(GetArea())
	Local cObservacoes	:= ""
	Local oDlgObs		:= Nil

	Default cCodCliente	:= ""
	Default cCodLoja	:= ""

	SA1->(DbSelectArea(1))
	If SA1->(MsSeek(xFilial("SA1")+cCodCliente+cCodLoja))

		// observacoes do cliente
		cObservacoes := SA1->A1_XOBSFAT

		If !Empty(cObservacoes)

			//Define Font oFont Name "Mono AS" Size 5, 12
			Define MsDialog oDlgObs Title "Observações do Cliente:" From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cObservacoes When .F. Memo Size 200, 145 Of oDlgObs Pixel
			oMemo:bRClicked := { || AllwaysTrue() }			

			Define SButton From 153, 175 Type 1 Action oDlgObs:End() Enable Of oDlgObs Pixel // OK			

			Activate MsDialog oDlgObs Center

		Else
			MsgAlert("Não existem observações de faturamento para o cliente!.","Atenção")

		EndIf

	EndIf

	RestArea(aAreaSA1)
	RestArea(aArea)

Return(Nil)

//Processa o estorno de notas fiscais em JOB, pois há um bug no fonte LOJR130
//o BUG: Após estornar uma nota, ao tentar gerar qq outra, o sistema não gera mais por conta
// da variavel Static lEstorno que não é resetada
User Function TRE042ES(cEmp, cFil, aNfEstorno)

	Local lRet := .F.
    Local nX
    Local nQtdNfe := len(aNfEstorno)
    Local lNota := .F. //Informa se é geração ou estorno da NF (T=Gerar, F=Estornar)

    if nQtdNfe == 0
        Return
    endif

	/*LojR130()
		SetMvValue("LJR131", "MV_PAR01", CTOD(aReg[nPosSel][nPosEmissao]))
		SetMvValue("LJR131", "MV_PAR02", CTOD(aReg[nPosSel][nPosEmissao]))
		SetMvValue("LJR131", "MV_PAR03", aReg[nPosSel][nPosVenda])
		SetMvValue("LJR131", "MV_PAR04", aReg[nPosSel][nPosSerie])
		SetMvValue("LJR131", "MV_PAR05", aReg[nPosSel][nPosVenda])
		SetMvValue("LJR131", "MV_PAR06", aReg[nPosSel][nPosSerie])
		SetMvValue("LJR131", "MV_PAR07", aReg[nPosSel][nPosCli])
		SetMvValue("LJR131", "MV_PAR08", aReg[nPosSel][nPosLoja])
		SetMvValue("LJR131", "MV_PAR09", 2)
		SetMvValue("LJR131", "MV_PAR10", SF2->F2_CLIENTE)
		SetMvValue("LJR131", "MV_PAR11", SF2->F2_LOJA)
	*/

    RPCSetType(3)		
    RPCSetEnv( cEmp, cFil, Nil, Nil,"FRT")

	Private lMsHelpAuto := .T. // Variavel de controle interno do ExecAuto
	Private lMsErroAuto := .F. // Variavel que informa a ocorrência de erros no ExecAuto

    for nX := 1 to nQtdNfe
        
        lMsErroAuto := .F.

        SetMvValue("LJR131", "MV_PAR10", "")
        SetMvValue("LJR131", "MV_PAR11", "")
        MV_PAR10 := ""
        MV_PAR11 := ""

        //Chama a rotina de nota sobre cupom
        LojR130(aNfEstorno, lNota, aNfEstorno[nX][3], aNfEstorno[nX][4])

        If lMsErroAuto 
            MostraErro()
		else
			lRet := .T.
        EndIf
        
    next nX

    RPCClearEnv()

Return lRet

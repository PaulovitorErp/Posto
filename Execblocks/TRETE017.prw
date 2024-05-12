#include "protheus.ch"
#include "topconn.ch"
#Include "TBICONN.CH"

#DEFINE GRIDMAXLIN 10000

STATIC lFatConv 	:= SuperGetMv("MV_XFTCONV",,.F.) //define se abrira modo faturamento conveniencia
STATIC cDBMS		:= UPPER(TcGetDb())

Static aCfgCampos, aCfgCpDefault, nPosMark, nPosLegend
Static nPosFilial, nPosFilOri, nPosTipo, nPosOriFat, nPosDescri, nPosPrefixo, nPosNumero, nPosParcela, nPosNaturez, nPosPortado, nPosDeposit
Static nPosNConta, nPosBanco, nPosPlaca, nPosCliente, nPosLoja, nPosNome, nPosClasse, nPosCondPg, nPosEmissao, nPosVencto, nPosValor, nPosSaldo
Static nPosDescont, nPosMulta, nPosJuros, nPosAcresc, nPosDecres, nPosVlAcess, nPosFatura, nPosRecno, nPosMotiv, nPosProdOs, nPosNCFret, nPosNMutuo
Static nPosNsuTef, nPosDocTef, nPosCartAu, nPosCGC, nPosObsFat, nPosMailFat
Static aDefFilter := {} //armazeno o conteudo padrão dos campos de filtro, para botão reset e validação de não edição de filtro

Static cFImpBol := SuperGetMv("MV_XFUNBOL",.F.,"TRETR009") //fonte para impressao de boletos
Static cFImpFat := SuperGetMv("MV_XFUNFAT",.F.,"TRETE020") //fonte para impressao da fatura
Static lLogRen	:= SuperGetMv("MV_XMOTREN",.F.,.F.) .AND. ChkFile("U0J") //parametro para renegociação
Static lLogExc	:= SuperGetMv("MV_XMOTEXF",.F.,.F.) .AND. ChkFile("U0J")
Static lLogMail	:= SuperGetMv("MV_XLGMAIL",.F.,.F.) .AND. ChkFile("U0J")

/*/{Protheus.doc} TRETE017
Faturamento Manual v2
@author Maiki Perin
@since 07/03/2019
@version P12
@param Nao recebe parametros
@return nulo
TESTE
/*/

/***********************/
User Function TRETE017()
/***********************/

	Local cTitulo 		:= "Faturamento Manual V2"

	Local aCabec		:= U_TRE017CP(1) //array com descriçao dos campos do grid
	Local aLarg			:= U_TRE017CP(2) //array com largura dos campos do grid

	Local oBmp1, oBmp2, oBmp3, oBmp4, oBmp5

	Local oMenuFat, oIt1Fat, oIt2Fat, oIt3Fat, oIt4Fat, oIt5Fat, oIt6Fat, oIt7Fat, oIt8Fat, oIt9Fat
	Local oMenuBol, oIt1Bol, oIt2Bol, oIt4Bol //oIt3Bol
	Local oMenuNf, oIt1Nf, oIt2Nf, oIt3Nf, oIt4Nf, oIt5Nf
	Local oMenuDiv, oIt1Div, oIt2Div, oIt3Div, oIt4Div, oIt5Div, oIt6Div

	Local nPosTit
	Local aObjects, aSizeAut, aInfo, aPosObj

	Private lPDFFat		:= SuperGetMv("MV_XPDFFAT",.F.,.T.) //define se gera automatico o PDF da fatura no servidor, durante o processamento da fatura
	Private lGeraNF		:= SuperGetMv("MV_XGERANF",.F.,.T.)
	Private lAltSac		:= SuperGetMv("MV_XALTSAC",.F.,.T.)
	Private cTpFat		:= SuperGetMv("MV_XFPGFAT",.F.,"NP/BOL/RP/CF/FT/CC/CCP/CD/CDP/DP/CT/CTF/NF/VLS/RE/REN/CN/PX")
	Private lValDupl	:= SuperGetMV("MV_XFVALDP",.F.,.F.)

	Private oFolderFat
	Private oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12, oSay13, oSay14, oSay15, oSay16, oSay17, oSay18
	Private oSay19, oSay20, oSay21, oSay22, oSay23, oSay24, oSay25, oSay26, oSay27, oSay28, oSay29, oSay30, oSay31, oSay32, oSay33, oSay34, oSay35
	Private oSay36, oSay37
	Private oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet10, oGet11, oGet12, oGet13, oGet14, oGet15, oGet16, oGet17, oGet18, oGet19, oGet20, oGet21, oGet22
	Private oGet23, oGet24, oGet25, oGet26
	Private oSit
	Private oCheckBox1, oCheckBox2, oCheckBox3, /*oCheckBox4,*/ oCheckBox5, oCheckBox6, oCheckBox7, oCheckBox8, oCheckBox9

	Private cGet4		:= Space(len(cFilAnt)) //Filial ?
	Private cGet5		:= Space(25) //Usuário reps. cliente ?
	Private cGet6		:= Space(200) //Cliente ?
	Private cGet7		:= Space(200) //Grupo Cliente ?
	Private cGet8		:= Space(200) //Filiais Origem ?  ou Segmento Cliente ?
	Private cGet9		:= Space(200) //Condição de Pagamento ?
	Private cGet10		:= Space(200) //Forma de Pagamento ?
	Private cGet11		:= Space(200) //Produto ?
	Private cGet12		:= Space(200) //Grupo de Produto ?
	Private dGet13		:= CToD("") //Emissão de ?
	Private dGet14		:= CToD("") //Emissão ate ?
	Private dGet15		:= CToD("") //Vencimento de ?
	Private dGet16		:= CToD("") //Vencimento ate ?
	Private cGet17		:= Space(200) //Classe Cliente ?
	Private cGet18		:= Space(200) //Motivo saque ?
	Private dGet19		:= CToD("") //Dt. p/ fatura de ?
	Private dGet20		:= CToD("") //Dt. p/ fatura ate ?
	Private cGet21 		:= Space(TamSX3("E1_NUM")[1]) //Título de ?
	Private cGet22 		:= Space(TamSX3("E1_NUM")[1]) //Título ate ?
	Private cGet23		:= IIF(!lFatConv,Space(TamSX3("DA3_PLACA")[1]),"") //Placa ?
	Private dGet24		:= dDataBase //Dt. referencia ?
	Private cGet25		:= "" //Obs. Impressão Fatura
	Private cGet26		:= Space(TamSX3("E1_HIST")[1]) //Obs. Titulo Fatura

	Private lCheckBox1	:= .T. //Título em aberto
	Private lCheckBox2	:= .F. //Baixado parcial
	Private lCheckBox3	:= .F. //Título Baixado
	Private lCheckBox4	:= .F. //Somente Fatura
	Private lCheckBox5	:= .F. //Bol. relacionado
	Private lCheckBox6 	:= .F. //NF relacionada
	Private lCheckBox7 	:= .T. //Indiferente Bol.
	Private lCheckBox8 	:= .T. //Indiferente NF
	Private lCB10 		:= .F. //Considerar títulos c/ prefixo 'IMP'

	Private cStatusMail	:= "I" //Status do envio de email da fatura
	Private aStatusMail	:= {"I=Indiferente","E=Email Enviado","N=Email Não Enviado"}

	//armazeno o conteudo padrão dos campos de filtro, para botão reset e validação de não edição de filtro
	aDefFilter := { ;
		{"cGet4", cGet4}, ; //Filial ?
		{"cGet5", cGet5}, ; //Usuário reps. cliente ?
		{"cGet6", cGet6}, ; //Cliente ?
		{"cGet7", cGet7}, ; //Grupo Cliente ?
		{"cGet8", cGet8}, ; //Filiais Origem ?  ou Segmento Cliente ?
		{"cGet9", cGet9}, ; //Condição de Pagamento ?
		{"cGet10", cGet10}, ; //Forma de Pagamento ?
		{"cGet11", cGet11}, ; //Produto ?
		{"cGet12", cGet12}, ; //Grupo de Produto ?
		{"dGet13", dGet13}, ; //Emissão de ?
		{"dGet14", dGet14}, ; //Emissão ate ?
		{"dGet15", dGet15}, ; //Vencimento de ?
		{"dGet16", dGet16}, ; //Vencimento ate ?
		{"cGet17", cGet17}, ; //Classe Cliente ?
		{"cGet18", cGet18}, ; //Motivo saque ?
		{"dGet19", dGet19}, ; //Dt. p/ fatura de ?
		{"dGet20", dGet20}, ; //Dt. p/ fatura ate ?
		{"cGet21", cGet21}, ; //Título de ?
		{"cGet22", cGet22}, ; //Título ate ?
		{"cGet23", cGet23}, ; //Placa ?
		{"dGet24", dGet24}, ; //Dt. referencia ?
		{"cGet25", cGet25}, ; //Obs. Impressão Fatura
		{"cGet26", cGet26}, ; //Obs. Titulo Fatura
		{"lCheckBox1", lCheckBox1}, ; //Título em aberto
		{"lCheckBox2", lCheckBox2}, ; //Baixado parcial
		{"lCheckBox3", lCheckBox3}, ; //Título Baixado
		{"lCheckBox4", lCheckBox4}, ; //Somente Fatura
		{"lCheckBox5", lCheckBox5}, ; //Bol. relacionado
		{"lCheckBox6", lCheckBox6}, ; //NF relacionada
		{"lCheckBox7", lCheckBox7}, ; //Indiferente Bol.
		{"lCheckBox8", lCheckBox8}, ; //Indiferente NF
		{"cStatusMail", cStatusMail}, ; //Status do envio de email da fatura
		{"lCB10", lCB10} ; //Considerar títulos c/ prefixo 'IMP'
	}

	Private oButton1, oButton2, _OBTNCLOSE, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9, oButton10, oButton11, oButton12, oButton13
	Private oButton14, oButton15, oButton16, oButton17, oButton18, oButton19, oButton20, oButton21, oButton22, oButton23, oButton24, oButton25, oButton26
	Private oButton27, oButton28, oButton29, oButton30

	Private oOkMark		:= LoadBitmap(GetResources(),"LBOK")
	Private oNoMark		:= LoadBitmap(GetResources(),"LBNO")

	Private oLeg
	Private oVerde		:= LoadBitmap(GetResources(),"BR_VERDE")
	Private oAzul		:= LoadBitmap(GetResources(),"BR_AZUL")
	Private oMarrom		:= LoadBitmap(GetResources(),"BR_MARROM")
	Private oVermelho	:= LoadBitmap(GetResources(),"BR_VERMELHO")
	Private oAmarelo	:= LoadBitmap(GetResources(),"BR_AMARELO")

	Private aLinEmpty   := U_TRE017CP(3) //array com linha em branco
	Private aReg		:= {aClone(aLinEmpty)}
	
	Private oBrw
	Private bBrwLine	:= U_TRE017CP(4) //bloco de atualização da linha

	Private nCont := nTotBrut := nTotLiq := nAux := 0

	Private lFiltro		:= .T.

	Private nColOrder	:= 0

	Private lEnvArqs	:= SuperGetMv("MV_XENVARQ",.F.,.T.)
	Private cEmails		:= ""

	Private cBkpFil := cFilAnt
	Private lEnd := .F.

	//Public __aArqPDF	:= {}

	Static oDlgT017

	If AllTrim(FunName()) == "TMKA271" .Or. AllTrim(FunName()) == "TMKA380" //Origem da chamada for a rotina Telecobrança ou Agenda do Operador

		nPosTit := aScan(aHeader,{|x| AllTrim(x[2])=="ACG_TITULO"})

		If Empty(M->ACF_CLIENT)
			MsgInfo("Para acesso a rotina de Renegocição, é necessário a seleção de Cliente.","Atenção")
			Return
		Endif

		cGet6 		:= M->ACF_CLIENT
		dGet20		:= CToD("")
		lCheckBox7	:= .T.
		lCheckBox8	:= .T.
	Endif

	aObjects := {}
	aSizeAut := MsAdvSize()

// Largura, Altura, Modifica largura, Modifica altura
	aAdd(aObjects,{100, 090, .T., .T.}) // Folder
	aAdd(aObjects,{100, 005, .T., .F.}) // Linha horizontal
	aAdd(aObjects,{100, 005, .F., .F.}) // Botões

	aInfo 	:= {aSizeAut[1],aSizeAut[2],aSizeAut[3],aSizeAut[4],3,3}
	aPosObj := MsObjSize(aInfo,aObjects,.T.)

	DEFINE MSDIALOG oDlgT017 TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

// Scroll
//oScr := TScrollBox():New(oDlgT017,aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,4],aPosObj[1,3] - 10,.T.,.T.,.T.)

// Folder
	@ aPosObj[1,1] - 30, aPosObj[1,2] FOLDER oFolderFat SIZE aPosObj[1,4], aPosObj[1,3] - 10 OF /*oScr*/ oDlgT017 ITEMS "Filtro","Títulos" COLORS 0, 16777215 PIXEL
	oFolderFat:nOption := 1
	//oFolderFat:bChange := {|| HabBotoes()}
	oFolderFat:BSETOPTION := {|| HabBotoes() } //valida se pode ir para a abas

//Pasta Filtro
	@ 005, 005 SAY oSay4 PROMPT "Filial ?" SIZE 030, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 004, 080 MSGET oGet4 VAR cGet4 SIZE 030, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SM0" Picture "@!"
	if len(Alltrim(xFilial("SE1"))) != len(cFilAnt) //verifico se SE1 é compartilhada e oculto esse filtro
		oSay4:lVisible := .F.
		oGet4:lVisible := .F.
	endif

	If !lFatConv // Diferente de conveniência
		@ 018, 005 SAY oSay5 PROMPT "Usuário reps. cliente ?" SIZE 060, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 017, 080 MSGET oGet5 VAR cGet5 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "USR" Picture "@!"
	EndIf

	@ 031, 005 SAY oSay6 PROMPT "Cliente ?" SIZE 030, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 030, 080 GET oGet6 VAR cGet6 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL;
		VALID {||cGet6 := AllTrim(cGet6),cGet6 := Upper(cGet6),.T.}
	@ 030, 187 BUTTON oButton7 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilCli(cGet6) PIXEL
	@ 045, 187 BUTTON oButton8 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION (LimpMemo(@oGet6,@cGet6)/*,oGet6:lReadOnly := .F.*/) PIXEL

	@ 073, 005 SAY oSay7 PROMPT "Grupo Cliente ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 072, 080 GET oGet7 VAR cGet7 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 075, 187 BUTTON oButton9 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilGrpCli() PIXEL
	@ 087, 187 BUTTON oButton10 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet7,@cGet7) PIXEL
	oGet7:lReadOnly := .T.

	if len(Alltrim(xFilial("SE1"))) != len(cFilAnt) //verifico se SE1 é compartilhada e troco o filtro de Segmento por filtro de Filial
		@ 115, 005 SAY oSay8 PROMPT "Filiais Origem ?" SIZE 080, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 114, 080 GET oGet8 VAR cGet8 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 114, 187 BUTTON oButton11 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilFilialOri() PIXEL
		@ 129, 187 BUTTON oButton12 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet8,@cGet8) PIXEL
		oGet8:lReadOnly := .T.
	else
		@ 115, 005 SAY oSay8 PROMPT "Segmento Cliente ?" SIZE 080, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 114, 080 GET oGet8 VAR cGet8 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 114, 187 BUTTON oButton11 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilSegCli() PIXEL
		@ 129, 187 BUTTON oButton12 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet8,@cGet8) PIXEL
		oGet8:lReadOnly := .T.
	endif

	If !lFatConv // Diferente de conveniência
		@ 157, 005 SAY oSay24 PROMPT "Classe Cliente ?" SIZE 080, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 156, 080 GET oGet17 VAR cGet17 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 156, 187 BUTTON oButton22 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilClaCli() PIXEL
		@ 171, 187 BUTTON oButton23 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet17,@cGet17) PIXEL
		oGet17:lReadOnly := .T.

		@ 199, 005 SAY oSay9 PROMPT "Condição de Pagamento ?" SIZE 070, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 198, 080 GET oGet9 VAR cGet9 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 198, 187 BUTTON oButton13 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilCond() PIXEL
		@ 213, 187 BUTTON oButton14 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet9,@cGet9) PIXEL
		oGet9:lReadOnly := .T.

		@ 005, 245 SAY oSay27 PROMPT "Motivo saque ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 004, 320 GET oGet18 VAR cGet18 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 004, 427 BUTTON oButton28 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilMotSaq() PIXEL
		@ 019, 427 BUTTON oButton29 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet18,@cGet18) PIXEL
		oGet18:lReadOnly := .T.

		@ 047, 245 SAY oSay10 PROMPT "Forma de Pagamento ?" SIZE 060, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 046, 320 GET oGet10 VAR cGet10 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL;
			VALID {||cGet10 := AllTrim(cGet10),cGet10 := Upper(cGet10),.T.}
		@ 046, 427 BUTTON oButton15 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilFormaPg() PIXEL
		@ 061, 427 BUTTON oButton16 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet10,@cGet10) PIXEL

		@ 089, 245 SAY oSay11 PROMPT "Produto ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 088, 320 GET oGet11 VAR cGet11 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 088, 427 BUTTON oButton17 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilProd() PIXEL
		@ 103, 427 BUTTON oButton18 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet11,@cGet11) PIXEL
		oGet11:lReadOnly := .T.

		@ 131, 245 SAY oSay12 PROMPT "Grupo de Produto ?" SIZE 060, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 130, 320 GET oGet12 VAR cGet12 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 130, 427 BUTTON oButton19 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilGrpProd() PIXEL
		@ 145, 427 BUTTON oButton20 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet12,@cGet12) PIXEL
		oGet12:lReadOnly := .T.

	Else

		@ 031, 245 SAY oSay10 PROMPT "Forma de Pagamento ?" SIZE 060, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 030, 320 GET oGet10 VAR cGet10 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL;
			VALID {||cGet10 := AllTrim(cGet10),cGet10 := Upper(cGet10),.T.}
		@ 030, 427 BUTTON oButton15 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilFormaPg() PIXEL
		@ 045, 427 BUTTON oButton16 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet10,@cGet10) PIXEL

		@ 073, 245 SAY oSay11 PROMPT "Produto ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 072, 320 GET oGet11 VAR cGet11 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 072, 427 BUTTON oButton17 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilProd() PIXEL
		@ 087, 427 BUTTON oButton18 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet11,@cGet11) PIXEL
		oGet11:lReadOnly := .T.

		@ 115, 245 SAY oSay12 PROMPT "Grupo de Produto ?" SIZE 060, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 114, 320 GET oGet12 VAR cGet12 MEMO SIZE 100, 040 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 114, 427 BUTTON oButton19 PROMPT "Buscar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION FilGrpProd() PIXEL
		@ 129, 427 BUTTON oButton20 PROMPT "Limpar" SIZE 040, 010 OF oFolderFat:aDialogs[1] ACTION LimpMemo(@oGet12,@cGet12) PIXEL
		oGet12:lReadOnly := .T.
	EndIf

	@ 173, 245 GROUP oSit TO 220, 470 PROMPT "Situações do título" OF oFolderFat:aDialogs[1] COLOR 0, 16777215 PIXEL
	@ 190, 255 CHECKBOX oCheckBox1 VAR lCheckBox1 PROMPT "Título em aberto"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	@ 190, 310 CHECKBOX oCheckBox2 VAR lCheckBox2 PROMPT "Baixado parcial"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	@ 190, 365 CHECKBOX oCheckBox3 VAR lCheckBox3 PROMPT "Título Baixado"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	@ 190, 420 CHECKBOX oCheckBox4 VAR lCheckBox4 PROMPT "Somente Fatura"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL

	@ 208, 255 CHECKBOX oCheckBox5 VAR lCheckBox5 PROMPT "Bol. relacionado"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	oCheckBox5:bChange := ({||CliqueBol(1)})
	@ 208, 310 CHECKBOX oCheckBox7 VAR lCheckBox7 PROMPT "Indiferente Bol."  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	oCheckBox7:bChange := ({||CliqueBol(2)})
	@ 208, 365 CHECKBOX oCheckBox6 VAR lCheckBox6 PROMPT "NF relacionada"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	oCheckBox6:bChange := ({||CliqueNf(1)})
	If !lGeraNF
		oCheckBox6:lVisible := .F.
	Endif
	@ 208, 420 CHECKBOX oCheckBox8 VAR lCheckBox8 PROMPT "Indiferente NF"  Size 070, 007 PIXEL OF oSit COLORS 0, 16777215 PIXEL
	oCheckBox8:bChange := ({||CliqueNf(2)})
	If !lGeraNF
		oCheckBox8:lVisible := .F.
	Endif

	@ 225,245 SAY "Status Envio E-mail" Size 050,007 COLOR CLR_BLACK PIXEL OF oFolderFat:aDialogs[1]
	@ 223,320 COMBOBOX cStatusMail Items aStatusMail Size 080,010 PIXEL OF oFolderFat:aDialogs[1]

	@ 005, 515 SAY oSay13 PROMPT "Emissão de ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 004, 570 MSGET oGet13 VAR dGet13 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 017, 515 SAY oSay14 PROMPT "Emissão ate ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 016, 570 MSGET oGet14 VAR dGet14 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 029, 515 SAY oSay28 PROMPT "Dt. p/ fatura de ?" SIZE 050, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 028, 570 MSGET oGet19 VAR dGet19 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 041, 515 SAY oSay29 PROMPT "Dt. p/ fatura ate ?" SIZE 050, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 040, 570 MSGET oGet20 VAR dGet20 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 053, 515 SAY oSay15 PROMPT "Vencimento de ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 052, 570 MSGET oGet15 VAR dGet15 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 065, 515 SAY oSay16 PROMPT "Vencimento ate ?" SIZE 050, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 064, 570 MSGET oGet16 VAR dGet16 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 077, 515 SAY oSay30 PROMPT "Título de ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 076, 570 MSGET oGet21 VAR cGet21 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SE1FAT"

	@ 089, 515 SAY oSay31 PROMPT "Título ate ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 088, 570 MSGET oGet22 VAR cGet22 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "SE1FAT"

	If !lFatConv // Diferente de conveniência
		@ 101, 515 SAY oSay32 PROMPT "Placa ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 100, 570 MSGET oGet23 VAR cGet23 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL F3 "DA3" PICTURE "@!R NNN-9N99"
	EndIf

	@ 113, 515 SAY oSay33 PROMPT "Dt. referencia ?" SIZE 040, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 112, 570 MSGET oGet24 VAR dGet24 SIZE 060, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL

	@ 125, 515 CHECKBOX oCB10 VAR lCB10 PROMPT "Considerar títulos c/ prefixo 'IMP'"  Size 120, 007 PIXEL OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL

	@ 137, 515 SAY oSay37 PROMPT "Obs. Impressão Fatura" SIZE 120, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 145, 515 GET oGet25 VAR cGet25 MEMO SIZE 110, 035 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL VALID (cGet25 := Upper(cGet25),.T.)

	@ 185, 515 SAY oSay37 PROMPT "Obs. Titulo Fatura" SIZE 120, 007 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL
	//@ 193, 515 GET oGet26 VAR cGet26 MEMO SIZE 100, 025 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 PIXEL VALID (cGet26 := Upper(cGet26))
	@ 193, 515 MSGET oGet26 VAR cGet26 SIZE 110, 010 OF oFolderFat:aDialogs[1] COLORS 0, 16777215 HASBUTTON PIXEL Picture "@!"

// Pasta Faturamento
// Browse
	oBrw := TWBrowse():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,4] - 10,aPosObj[1,3] - 55,,aCabec,aLarg,oFolderFat:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.)
	oBrw:SetArray(aReg)
	oBrw:blDblClick 	:= {|| MarkReg()}
	oBrw:bHeaderClick 	:= {|oObj,nCol| IIF(nCol ==1 ,MarkAllReg(),),(OrderGrid(oBrw,nCol), nColOrder := nCol)}
	oBrw:bLine := bBrwLine

// Cria Menu Fatura
	oMenuFat := TMenu():New(0,0,0,0,.T.)
// Adiciona itens no Menu Fatura
	oIt1Fat := TMenuItem():New(oDlgT017,"Gerar",,,,{||FWMsgRun(,{|oSay| Faturar(oSay)},'Aguarde','Gerando fatura...')},,,,,,,,,.T.)
	oIt2xFat := TMenuItem():New(oDlgT017,"Gerar - Alt.Vencimento",,,,{||FWMsgRun(,{|oSay| Faturar(oSay,,.T.)},'Aguarde','Gerando fatura...')},,,,,,,,,.T.)
	oIt2Fat := TMenuItem():New(oDlgT017,"Flexível",,,,{||FWMsgRun(,{|oSay| FatFlex(oSay)},'Aguarde','Gerando fatura...')},,,,,,,,,.T.)
	//oIt2yFat := TMenuItem():New(oDlgT017,"Flexível - Multiplo",,,,{||FWMsgRun(,{|oSay| Faturar(oSay, .T.)},'Aguarde','Gerando fatura...')},,,,,,,,,.T.)
	oIt7Fat := TMenuItem():New(oDlgT017,"Individual",,,,{||FWMsgRun(,{|oSay| FatInd(oSay)},'Aguarde','Gerando fatura individual...')} ,,,,,,,,,.T.)
	oIt3Fat := TMenuItem():New(oDlgT017,"Cancelar",,,,{||FWMsgRun(,{|oSay| CanFat(oSay)},'Aguarde','Cancelando fatura...')} ,,,,,,,,,.T.)
	oIt8Fat := TMenuItem():New(oDlgT017,"Parcelar",,,,{||FWMsgRun(,{|oSay| FatParc(oSay)},'Aguarde','Gerando fatura parcelada...')} ,,,,,,,,,.T.)
	oIt9Fat := TMenuItem():New(oDlgT017,"Est. Parcelamento",,,,{||FWMsgRun(,{|oSay| EstRen(oSay, .T.)},'Aguarde','Estornando parcelamento...')} ,,,,,,,,,.T.)
	oIt4Fat := TMenuItem():New(oDlgT017,"Detalhar",,,,{||FWMsgRun(,{|oSay| DetFat(oSay)},'Aguarde','Detalhando fatura...')} ,,,,,,,,,.T.)
	oIt5Fat := TMenuItem():New(oDlgT017,"Imprimir - Direto na porta",,,,{||FWMsgRun(,{|oSay| ImpFat(oSay,1)},'Aguarde','Imprimindo fatura...')} ,,,,,,,,,.T.)
	oIt6Fat := TMenuItem():New(oDlgT017,"Imprimir - Em tela",,,,{||FWMsgRun(,{|oSay| ImpFat(oSay,2)},'Aguarde','Imprimindo fatura...')} ,,,,,,,,,.T.)
	oIt10Fat := TMenuItem():New(oDlgT017,"Fatura em Excel",,,,{||FWMsgRun(,{|oSay| ImpFat(oSay,3) },'Aguarde','Exportando fatura...')} ,,,,,,,,,.T.)

	oMenuFat:Add(oIt1Fat)
	oMenuFat:Add(oIt2xFat)
	oMenuFat:Add(oIt2Fat)
	oMenuFat:Add(oIt7Fat)
	oMenuFat:Add(oIt3Fat)
	oMenuFat:Add(oIt8Fat)
	oMenuFat:Add(oIt9Fat)
	oMenuFat:Add(oIt4Fat)
	oMenuFat:Add(oIt5Fat)
	oMenuFat:Add(oIt6Fat)
	If GetRemoteType() <= 2 //só se windows ou linux ou mac
		oMenuFat:Add(oIt10Fat)
	endif

	@ aPosObj[3,1] - 10, aPosObj[3,2] BUTTON oButton4 PROMPT "Fatura" SIZE 050, 013 OF oDlgT017 PIXEL
	oButton4:SetPopupMenu(oMenuFat)

// Cria Menu Boleto
	oMenuBol := TMenu():New(0,0,0,0,.T.)
// Adiciona itens no Menu Boleto
	oIt1Bol := TMenuItem():New(oDlgT017,"Gerar/Imprimir - Direto na porta",,,,{|| FWMsgRun(,{|oSay| ImpBol(oSay,1)},'Aguarde','Imprimindo boleto bancário...')},,,,,,,,,.T.)
	oIt2Bol := TMenuItem():New(oDlgT017,"Gerar/Imprimir - Em tela",,,,{||FWMsgRun(,{|oSay| ImpBol(oSay,3)},'Aguarde','Imprimindo boleto bancário...')} ,,,,,,,,,.T.)
	//oIt3Bol := TMenuItem():New(oDlgT017,"Gerar/Imprimir - Enviar por E-Mail",,,,{||FWMsgRun(,{|oSay| ImpBol(oSay,2)},'Aguarde','Enviando...')} ,,,,,,,,,.T.)
	oIt4Bol := TMenuItem():New(oDlgT017,"Transferir - Borderô => Carteira",,,,{||FWMsgRun(,{|oSay| TransMBol(oSay)},'Aguarde','Transferindo...')},,,,,,,,,.T.)
	oIt5Bol := TMenuItem():New(oDlgT017,"Selecionar Banco",,,,{|| U_TRETR09A() },,,,,,,,,.T.)

	oMenuBol:Add(oIt1Bol)
	oMenuBol:Add(oIt2Bol)
	//oMenuBol:Add(oIt3Bol)
	oMenuBol:Add(oIt4Bol)
	oMenuBol:Add(oIt5Bol)

	@ aPosObj[3,1] - 10, aPosObj[3,2] + 60 BUTTON oButton24 PROMPT "Boleto" SIZE 050, 013 OF oDlgT017 PIXEL
	oButton24:SetPopupMenu(oMenuBol)

	@ aPosObj[3,1] - 10, aPosObj[3,2] + 120 BUTTON oButton5 PROMPT "Baixar" SIZE 050, 013 OF oDlgT017 ACTION Liq(aReg[oBrw:nAT][nPosRecno]) PIXEL

	// Cria Menu NF
	oMenuNf := TMenu():New(0,0,0,0,.T.)

	// Adiciona itens no Menu Fatura
	oIt1Nf := TMenuItem():New(oMenuNf,"Gerar",,,,{||GeraNFe()},,,,,,,,,.T.)
	oIt2Nf := TMenuItem():New(oMenuNf,"Estornar",,,,{||EstNfe()} ,,,,,,,,,.T.)
	oIt3Nf := TMenuItem():New(oMenuNf,"Imprimir DANFE",,,,{||ImpNfe()} ,,,,,,,,,.T.)
	
	if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
		oIt4Nf := TMenuItem():New(oMenuNf,"NF-e Sefaz",,,,{|| },,,,,,,,,.T.)
	else
		oIt4Nf := TMenuItem():New(oMenuNf,"NF-e Sefaz",,,,{|| CallNfeSefaz() },,,,,,,,,.T.)
	endif

	oIt5Nf := TMenuItem():New(oMenuNf,"Monitor de Notas",,,,{|| MonitorNotas() },,,,,,,,,.T.)

	If lGeraNF
		//oMenuNf:Add(oIt1Nf)
		//oMenuNf:Add(oIt2Nf)
		//oMenuNf:Add(oIt3Nf)
		oMenuNf:Add(oIt4Nf)
		oMenuNf:Add(oIt5Nf)
	Endif
	if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
		MenusNfeFil(@oIt4Nf)
	endif

	@ aPosObj[3,1] - 10, aPosObj[3,2] + 180 BUTTON oButton6 PROMPT "N. Fiscal" SIZE 050, 013 OF oDlgT017 PIXEL
	oButton6:SetPopupMenu(oMenuNf)

	@ aPosObj[3,1] - 8, aPosObj[3,2] + 245 SAY oSay25 PROMPT "|" SIZE 020, 007 OF oDlgT017 COLORS CLR_BLUE, 16777215 PIXEL

// Cria Menu Diversos
	oMenuDiv := TMenu():New(0,0,0,0,.T.)
// Adiciona itens no Menu Diversos
	oIt1Div := TMenuItem():New(oDlgT017,"Alterar Bco. Cobrança",,,,{||SelBco()},,,,,,,,,.T.)
	oIt2Div := TMenuItem():New(oDlgT017,"Renegociar Título",,,,{||Reneg()} ,,,,,,,,,.T.)
	oIt4Div := TMenuItem():New(oDlgT017,"Estornar Renegociação",,,,{||EstRen()} ,,,,,,,,,.T.)
	oIt3Div := TMenuItem():New(oDlgT017,"Visualizar venda",,,,{||VisCf(aReg[oBrw:nAT][nPosFilial],aReg[oBrw:nAT][nPosNumero],aReg[oBrw:nAT][nPosPrefixo],aReg[oBrw:nAT][nPosCliente],aReg[oBrw:nAT][nPosLoja])} ,,,,,,,,,.T.)
	oIt5Div := TMenuItem():New(oDlgT017,"Alterar Título",,,,{||AltTit()},,,,,,,,,.T.)
	oIt6Div := TMenuItem():New(oDlgT017,"Alterar Sacado Título",,,,{||AltSacTit()},,,,,,,,,.T.)
	oIt7Div := TMenuItem():New(oDlgT017,"Log Ações Faturas",,,,{|| U_TRETR018(Aviso("Log Fatura","Como deseja ver o log de fatura?",{"Relatório","Em Tela"})) },,,,,,,,,.T.)
	oIt8Div := TMenuItem():New(oDlgT017,"Enviar PDFs Email",,,,{|| EnvEmailCli() },,,,,,,,,.T.)
	oIt9Div := TMenuItem():New(oDlgT017,"Observacoes Cliente",,,,{|| ObsCliente(aReg[oBrw:nAT][nPosCliente],aReg[oBrw:nAT][nPosLoja]) },,,,,,,,,.T.)

	oMenuDiv:Add(oIt1Div)
	oMenuDiv:Add(oIt2Div)
	oMenuDiv:Add(oIt4Div)
	oMenuDiv:Add(oIt3Div)
	oMenuDiv:Add(oIt5Div)
	If lAltSac
		oMenuDiv:Add(oIt6Div)
	Endif
	if lLogExc .OR. lLogRen .OR. lLogMail
		oMenuDiv:Add(oIt7Div)
	endif
	oMenuDiv:Add(oIt8Div)
	if SA1->(FieldPos("A1_XOBSFAT")) > 0
		oMenuDiv:Add(oIt9Div)
	endif

	@ aPosObj[3,1] - 10, aPosObj[3,2] + 260 BUTTON oButton25 PROMPT "Diversos" SIZE 050, 013 OF oDlgT017 PIXEL
	oButton25:SetPopupMenu(oMenuDiv)

// Contador e Totalizador
	@ aPosObj[2,1] - 53, aPosObj[2,2] SAY oSay1 PROMPT "Registros selecionados:" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ aPosObj[2,1] - 53, aPosObj[2,2] + 60 SAY oSay2 PROMPT AllTrim(Transform(nCont,"@E 999,999")) SIZE 040, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 53, aPosObj[2,2] + 90 SAY oSay22 PROMPT ", totalizando R$" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ aPosObj[2,1] - 53, aPosObj[2,2] + 130 SAY oSay23 PROMPT AllTrim(Transform(nTotBrut,"@E 9,999,999,999,999.99")) + " (valor/valor bruto)" SIZE 120, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ aPosObj[2,1] - 53, aPosObj[2,2] + 240 SAY oSay35 PROMPT "R$ " + AllTrim(Transform(nTotLiq,"@E 9,999,999,999,999.99")) + " (saldo/valor liquido)" SIZE 120, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

// Legenda
	@ aPosObj[2,1] - 41, aPosObj[2,2] SAY oSay17 PROMPT "Legenda:" SIZE 040, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 35 BITMAP oBmp1 ResName "BR_VERDE" OF oFolderFat:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 41, aPosObj[2,2] + 50 SAY oSay18 PROMPT "Titulo em aberto" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 115 BITMAP oBmp2 ResName "BR_AZUL" OF oFolderFat:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 41, aPosObj[2,2] + 130 SAY oSay19 PROMPT "Baixado parcialmente" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 195 BITMAP oBmp3 ResName "BR_MARROM" OF oFolderFat:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 41, aPosObj[2,2] + 210 SAY oSay20 PROMPT "Fatura" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

	@ aPosObj[2,1] - 42, aPosObj[2,2] + 275 BITMAP oBmp4 ResName "BR_VERMELHO" OF oFolderFat:aDialogs[2] Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1] - 41, aPosObj[2,2] + 290 SAY oSay21 PROMPT "Titulo Baixado" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL

	If !lFatConv // Diferente de conveniência
		@ aPosObj[2,1] - 42, aPosObj[2,2] + 355 BITMAP oBmp5 ResName "BR_AMARELO" OF oFolderFat:aDialogs[2] Size 10,10 NoBorder PIXEL
		@ aPosObj[2,1] - 41, aPosObj[2,2] + 370 SAY oSay22 PROMPT "Origem NF Recuperada" SIZE 080, 007 OF oFolderFat:aDialogs[2] COLORS 0, 16777215 PIXEL
	EndIf

	@ aPosObj[2,1] - 50, aPosObj[2,4] - 97 BUTTON oButton27 PROMPT "Ver Prévia da Fatura" SIZE 070,013 OF oFolderFat:aDialogs[2] ACTION U_TRETE047(aSizeAut,aPosObj) PIXEL
	
	//Botão para reordenar colunas do grid //FWSKIN_ICON_CFG //FWSKIN_CONFIG_ICO //ENGRENAGEM
	oCfgButton := TBtnBmp2():New( (aPosObj[2,1]-50)*2, (aPosObj[2,4]-20)*2, 20, 26,'FWSKIN_CONFIG_ICO',,,, {|| ChangeGrid() },oFolderFat:aDialogs[2],,,.T. )
	//oCfgButton:SetCss("TBtnBmp2{border: none;background-color: none;}")

	// Linha horizontal
	@ aPosObj[2,1] - 10, aPosObj[2,2] SAY oSay3 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgT017 COLORS CLR_GRAY, 16777215 PIXEL

	@ aPosObj[3,1] - 10, aPosObj[1,4] - 160 BUTTON oButton27 PROMPT "Imprimir Grade" SIZE 060,013 OF oDlgT017 ACTION U_TRETR014(aReg) PIXEL
	@ aPosObj[3,1] - 10, aPosObj[1,4] - 110 BUTTON oButton1 PROMPT "Aplicar filtro" SIZE 060, 013 OF oDlgT017 ACTION ExecFiltro(1) PIXEL
	@ aPosObj[3,1] - 10, aPosObj[1,4] - 180 BUTTON oButton30 PROMPT "Limpar filtro" SIZE 060, 013 OF oDlgT017 ACTION LimpaFiltro(oDlgT017) PIXEL
	@ aPosObj[3,1] - 10, aPosObj[1,4] - 90 BUTTON oButton2 PROMPT "Filtro" SIZE 040, 013 OF oDlgT017 ACTION {||oFolderFat:ShowPage(1),;
		oButton1:lVisible 	:= .T.,;
		oButton30:lVisible 	:= .T.,;
		oButton2:lVisible 	:= .F.,;
		oButton4:lVisible 	:= .F.,;
		oButton24:lVisible 	:= .F.,;
		oButton25:lVisible 	:= .F.,;
		oSay25:lVisible 	:= .F.,;
		oButton27:lVisible 	:= .F.,;
		oButton5:lVisible 	:= .F.,;
		oButton6:lVisible 	:= .F.} PIXEL

	@ aPosObj[3,1] - 10, aPosObj[1,4] - 40 BUTTON _OBTNCLOSE PROMPT "Fechar" SIZE 040, 013 OF oDlgT017 ACTION oDlgT017:End() PIXEL

	oButton1:lVisible 	:= .T.
	oButton30:lVisible 	:= .T.
	oButton2:lVisible 	:= .F.
	oButton4:lVisible 	:= .F.
	oButton24:lVisible 	:= .F.
	oButton25:lVisible 	:= .F.
	oSay25:lVisible 	:= .F.
	oButton27:lVisible 	:= .F.
	oButton5:lVisible 	:= .F.
	oButton6:lVisible 	:= .F.

	oFolderFat:nOption := 1
	oFolderFat:SetOption(1)

	If !lFatConv // Diferente de conveniência
		oGet5:SetFocus()
	Else
		oGet6:SetFocus()
	EndIf

	If AllTrim(FunName()) == "TMKA271" .Or. AllTrim(FunName()) == "TMKA380" //Origem da chamada for a rotina Telecobrança
		HabBotoes()
		lFiltro := .F.
		oFolderFat:nOption := 2
	Endif

	ACTIVATE MSDIALOG oDlgT017 CENTERED

	cFilAnt := cBkpFil

Return

//Função gestão dos campos do Grid principal
User Function TRE017CP(nOpc, cVarPos)

	Local nPos := 0
	Local xRet
	Local aCabec := {}
	Local aSizes := {}
	Local aLinEmpty := {}
	Local aVarsPos := {}
	Local cBrwLin := ""

	Default cVarPos := "0"

	if aCfgCampos == Nil

		aadd(aCabec, "") //mark
		aadd(aSizes, 20)
		aadd(aLinEmpty, .F.)
		aadd(aVarsPos, "nPosMark")
		nPosMark := ++nPos

		aadd(aCabec, "") //legenda
		aadd(aSizes, 20)
		aadd(aLinEmpty, LoadBitmap(GetResources(),"BR_VERDE"))
		aadd(aVarsPos, "nPosLegend")
		nPosLegend := ++nPos

		aadd(aCabec, "Filial") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(Len(cFilAnt)))
		aadd(aVarsPos, "nPosFilial")
		nPosFilial := ++nPos

		if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
			aadd(aCabec, "Fil.Origem") 
			aadd(aSizes, 30)
			aadd(aLinEmpty, Space(Len(cFilAnt)))
			aadd(aVarsPos, "nPosFilOri")
			nPosFilOri := ++nPos
		endif

		aadd(aCabec, "Tipo") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(6))
		aadd(aVarsPos, "nPosTipo")
		nPosTipo := ++nPos

		aadd(aCabec, "Origem Fatura") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(15))
		aadd(aVarsPos, "nPosOriFat")
		nPosOriFat := ++nPos

		aadd(aCabec, "Descrição") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(55))
		aadd(aVarsPos, "nPosDescri")
		nPosDescri := ++nPos

		aadd(aCabec, "Prefixo") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(3))
		aadd(aVarsPos, "nPosPrefixo")
		nPosPrefixo := ++nPos

		aadd(aCabec, "Número") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(9))
		aadd(aVarsPos, "nPosNumero")
		nPosNumero := ++nPos

		aadd(aCabec, "Parcela") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(3))
		aadd(aVarsPos, "nPosParcela")
		nPosParcela := ++nPos

		aadd(aCabec, "Natureza") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(30))
		aadd(aVarsPos, "nPosNaturez")
		nPosNaturez := ++nPos

		aadd(aCabec, "Portador") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(3))
		aadd(aVarsPos, "nPosPortado")
		nPosPortado := ++nPos

		aadd(aCabec, "Depositaria") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(5))
		aadd(aVarsPos, "nPosDeposit")
		nPosDeposit := ++nPos

		aadd(aCabec, "Num da Conta") 
		aadd(aSizes, 60)
		aadd(aLinEmpty, Space(10))
		aadd(aVarsPos, "nPosNConta")
		nPosNConta := ++nPos

		aadd(aCabec, "Nome Banco") 
		aadd(aSizes, 40)
		aadd(aLinEmpty, Space(40))
		aadd(aVarsPos, "nPosBanco")
		nPosBanco := ++nPos

		if !lFatConv
			aadd(aCabec, "Placa") 
			aadd(aSizes, 40)
			aadd(aLinEmpty, Space(7))
			aadd(aVarsPos, "nPosPlaca")
			nPosPlaca := ++nPos
		endif
		
		if SA1->(FieldPos("A1_XOBSFAT")) > 0
			aadd(aCabec, "Obs.Faturamento") 
			aadd(aSizes, 30)
			aadd(aLinEmpty, Space(50))
			aadd(aVarsPos, "nPosObsFat")
			nPosObsFat := ++nPos
		endif

		aadd(aCabec, "Cliente") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(6))
		aadd(aVarsPos, "nPosCliente")
		nPosCliente := ++nPos

		aadd(aCabec, "Loja") 
		aadd(aSizes, 30)
		aadd(aLinEmpty, Space(2))
		aadd(aVarsPos, "nPosLoja")
		nPosLoja := ++nPos

		aadd(aCabec, "Nome") 
		aadd(aSizes, 140)
		aadd(aLinEmpty, Space(40))
		aadd(aVarsPos, "nPosNome")
		nPosNome := ++nPos
		
		aadd(aCabec, "CNPJ/CPF") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, Space(18))
		aadd(aVarsPos, "nPosCGC")
		nPosCGC := ++nPos

		if !lFatConv
			aadd(aCabec, "Classe") 
			aadd(aSizes, 40)
			aadd(aLinEmpty, Space(40))
			aadd(aVarsPos, "nPosClasse")
			nPosClasse := ++nPos
		endif

		aadd(aCabec, "Cond. pagto.") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, Space(15))
		aadd(aVarsPos, "nPosCondPg")
		nPosCondPg := ++nPos

		aadd(aCabec, "Dt. Emissão") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, CToD(""))
		aadd(aVarsPos, "nPosEmissao")
		nPosEmissao := ++nPos

		aadd(aCabec, "Dt. Vencimento") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, CToD(""))
		aadd(aVarsPos, "nPosVencto")
		nPosVencto := ++nPos

		aadd(aCabec, "Valor") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosValor")
		nPosValor := ++nPos

		aadd(aCabec, "Saldo") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosSaldo")
		nPosSaldo := ++nPos

		aadd(aCabec, "Desconto") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosDescont")
		nPosDescont := ++nPos

		aadd(aCabec, "Multa") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosMulta")
		nPosMulta := ++nPos

		aadd(aCabec, "Juros") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosJuros")
		nPosJuros := ++nPos

		aadd(aCabec, "Acréscimo") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosAcresc")
		nPosAcresc := ++nPos

		aadd(aCabec, "Decréscimo") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosDecres")
		nPosDecres := ++nPos

		aadd(aCabec, "Vlr Acessorios") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosVlAcess")
		nPosVlAcess := ++nPos

		aadd(aCabec, "Fatura") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, Space(9))
		aadd(aVarsPos, "nPosFatura")
		nPosFatura := ++nPos

		aadd(aCabec, "R_E_C_N_O_") 
		aadd(aSizes, 50)
		aadd(aLinEmpty, 0)
		aadd(aVarsPos, "nPosRecno")
		nPosRecno := ++nPos

		if !lFatConv
			aadd(aCabec, "Mot. Saque") 
			aadd(aSizes, 40)
			aadd(aLinEmpty, Space(9))
			aadd(aVarsPos, "nPosMotiv")
			nPosMotiv := ++nPos

			aadd(aCabec, "Prod. OS") 
			aadd(aSizes, 40)
			aadd(aLinEmpty, Space(6))
			aadd(aVarsPos, "nPosProdOs")
			nPosProdOs := ++nPos

			aadd(aCabec, "Num.Carta F.") 
			aadd(aSizes, 50)
			aadd(aLinEmpty, Space(6))
			aadd(aVarsPos, "nPosNCFret")
			nPosNCFret := ++nPos

			aadd(aCabec, "Cod.Mutuo") 
			aadd(aSizes, 40)
			aadd(aLinEmpty, Space(14))
			aadd(aVarsPos, "nPosNMutuo")
			nPosNMutuo := ++nPos

			aadd(aCabec, AllTrim(RetTitle("E1_NSUTEF"))) 
			aadd(aSizes, 50)
			aadd(aLinEmpty, Space(20))
			aadd(aVarsPos, "nPosNsuTef")
			nPosNsuTef := ++nPos

			aadd(aCabec, AllTrim(RetTitle("E1_DOCTEF"))) 
			aadd(aSizes, 50)
			aadd(aLinEmpty, Space(20))
			aadd(aVarsPos, "nPosDocTef")
			nPosDocTef := ++nPos

			aadd(aCabec, AllTrim(RetTitle("E1_CARTAUT"))) 
			aadd(aSizes, 50)
			aadd(aLinEmpty, Space(20))
			aadd(aVarsPos, "nPosCartAu")
			nPosCartAu := ++nPos

			aadd(aCabec, "Email Env.?") 
			aadd(aSizes, 30)
			aadd(aLinEmpty, Space(3))
			aadd(aVarsPos, "nPosMailFat")
			nPosMailFat := ++nPos

		endif

		aCfgCampos := {aCabec, aSizes, aLinEmpty, aVarsPos}
		aCfgCpDefault := aClone(aCfgCampos)

		//verifico se usuario tem salvo o profile, e ordeno
		cChave := FWGetProfString("TRETE017OC", "ORDGDCOLS", "NOCONFIG", .T.)
		if !empty(cChave) .AND. cChave <> "NOCONFIG"
			aCfgCampos := OrdByProfile(cChave)
			aCabec 		:= aCfgCampos[1]
			aSizes 		:= aCfgCampos[2]
			aLinEmpty 	:= aCfgCampos[3]
			aVarsPos 	:= aCfgCampos[4]
		endif

	else
		aCabec 		:= aCfgCampos[1]
		aSizes 		:= aCfgCampos[2]
		aLinEmpty 	:= aCfgCampos[3]
		aVarsPos 	:= aCfgCampos[4]
	endif

	if nOpc == 1 //retorna lista com nomes dos campos
		xRet := aClone(aCabec)
	elseif  nOpc == 2 //retorna array com largura dos campos
		xRet := aClone(aSizes)
	elseif  nOpc == 3 //retorna linha em branco para o grid
		xRet := aClone(aLinEmpty)
	elseif  nOpc == 4 //retorna bloco de codigo de atualização da linha
		cBrwLin := "{|| {"
		For nPos := 1 to len(aVarsPos)
			if nPos > 1
				cBrwLin += ", "
			endif
			if aVarsPos[nPos] == "nPosMark"
				cBrwLin += "IIF(aReg[oBrw:nAT]["+cValToChar(nPos)+"],oOkMark,oNoMark)"		
			else
				cBrwLin += "aReg[oBrw:nAT]["+cValToChar(nPos)+"]"
			endif
		next nPos
		cBrwLin += "}}"

		xRet := &(cBrwLin)
	elseif nOpc == 5 //retorna a posição do parametro 
		xRet := &(cVarPos)
	endif

Return xRet

/**************************/
Static Function HabBotoes()
/**************************/
	Local lCanGoFolder := .T.

	If oFolderFat:nOption == 2 //se está na aba 2, e está indo para 1
		//oFolderFat:SetOption(1)

		oButton1:lVisible 	:= .T.
		oButton30:lVisible 	:= .T.
		oButton2:lVisible 	:= .F.
		oButton4:lVisible 	:= .F.
		oButton24:lVisible 	:= .F.
		oButton25:lVisible 	:= .F.
		oSay25:lVisible 	:= .F.
		oButton27:lVisible 	:= .F.
		oButton5:lVisible 	:= .F.
		oButton6:lVisible 	:= .F.
	Else
		If !lFiltro
			lCanGoFolder := ExecFiltro(2)
		Else
			lFiltro := .F.
		Endif
	EndIf

Return lCanGoFolder

/***************************/
Static Function Filtro(lEnd)
/***************************/

	Local cQry 			:= ""
	Local nPosX5		:= 0
	Local aLinAux		:= {}
	Local cCli 			:= ""
	Local cGrpCli		:= ""
	Local cCond			:= ""
	Local cFormaPg		:= ""
	Local cProd			:= ""
	Local cSegCli		:= ""
	Local cFilOrig		:= ""
	Local cClasseCli	:= ""
	Local cMotSaq		:= ""
	Local cNumCFrete	:= ""
	Local cObsFatCli	:= ""

	Local cNat			:= "OUTROS    "
	Local cImpostos		:= ""

	Local lFa280Qry 	:= ExistBlock("FA280QRY")
	Local cQueryADD 	:= ""

	Local cTpTit		:= ""

	Local lConfCx		:= SuperGetMv("MV_XCONFCX",,.T.) //Exige conferência de caixa
	Local cSerieNF		:= SuperGetMv("MV_XSERFAT",.F.,"")
	//Local cSerVd		:= ""

	Local cNFRecu		:= SuperGetMv("MV_XNFRECU",.F.,"XPROTH/XCOPIA/XSEFAZ/XXML") //Tipos de recuperação de NF

	Local nVlrAcess := 0

	nCont		:= 0
	nTotBrut	:= 0
	nTotLiq		:= 0

	aSize(aReg,0) // Limpa o array

	cImpostos := Fa280VerImp(cNat)

	//Caso preencheu filial, altero o cFilAnt, para nao precisar tratar em todo o fonte. Ja passa a usar em tudo
	if !empty(cGet4)
		cFilAnt := cGet4
	else
		cFilAnt := cBkpFil
	endif

	If Empty(dGet24) .Or. dGet24 > dDataBase  // Data de referência inconsistente

		aSize(aReg,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg := nil
		aReg := {}
		aadd(aReg, aClone(aLinEmpty))

		oBrw:SetArray(aReg)
		oBrw:bLine := bBrwLine
		oBrw:nAt := 1
		oBrw:Refresh()

		oSay2:Refresh() // Contador
		oSay23:Refresh() // Totalizador
		oSay35:Refresh() // Totalizador

		oButton1:lVisible 	:= .F.
		oButton30:lVisible 	:= .F.
		oButton2:lVisible 	:= .T.
		oButton4:lVisible 	:= .T.
		oButton24:lVisible 	:= .T.
		oButton25:lVisible 	:= .T.
		oSay25:lVisible 	:= .T.
		oButton27:lVisible 	:= .T.
		oButton5:lVisible 	:= .T.

		If lGeraNF
			oButton6:lVisible 	:= .T.
		Endif

		oBrw:SetFocus()

		Return
	Endif

	If Select("QRYFAT") > 0
		QRYFAT->(DbCloseArea())
	EndIf

	//cQry := "SELECT "
	cQry := CRLF + "SE1.E1_FILIAL," //adicionado o CRLF ('pula linha') para ficar fácil o debug da query
	cQry += CRLF + " SE1.E1_FILORIG,"
	cQry += CRLF + " SE1.E1_TIPO,"
	cQry += CRLF + " SE1.E1_PREFIXO,"
	cQry += CRLF + " SE1.E1_NUM,"
	cQry += CRLF + " SE1.E1_PARCELA,"
	cQry += CRLF + " SED.ED_DESCRIC,"
	cQry += CRLF + " SE1.E1_PORTADO,"
	cQry += CRLF + " SE1.E1_AGEDEP,"
	cQry += CRLF + " SE1.E1_CONTA,"
	cQry += CRLF + " SA6.A6_NOME,"
	If !lFatConv // Diferente de conveniência
		cQry += CRLF + " SE1.E1_XPLACA,"
	EndIf
	cQry += CRLF + " SE1.E1_CLIENTE,"
	cQry += CRLF + " SE1.E1_LOJA,"
	cQry += CRLF + " SA1.A1_NOME,"
	cQry += CRLF + " SA1.A1_CGC,"
	If !lFatConv // Diferente de conveniência
		cQry += CRLF + " UF6.UF6_DESC,"
	EndIf
	cQry += CRLF + " SE4.E4_DESCRI,"
	cQry += CRLF + " SE1.E1_EMISSAO,"
	cQry += CRLF + " SE1.E1_VENCTO,"
	cQry += CRLF + " SE1.E1_VALOR,"
	cQry += CRLF + " SE1.E1_SALDO,"
	cQry += CRLF + " SE1.E1_DESCONT,"
	cQry += CRLF + " SE1.E1_MULTA,"
	cQry += CRLF + " SE1.E1_JUROS,"
	cQry += CRLF + " SE1.E1_ACRESC,"
	cQry += CRLF + " SE1.E1_DECRESC,"
	cQry += CRLF + " SE1.E1_FATURA,"
	cQry += CRLF + " SE1.R_E_C_N_O_ AS RECNO,"
	cQry += CRLF + " SF2.F2_DOC,"
	cQry += CRLF + " SF2.F2_SERIE,"
	If !lFatConv // Diferente de conveniência
		cQry += CRLF + " U57.U57_MOTIVO,"
		if SE1->(FieldPos("E1_XPRDOS")) > 0
			cQry += CRLF + " SE1.E1_XPRDOS,"
		endif
	EndIf
	cQry += CRLF + " SE1.E1_VLRREAL,"
	cQry += CRLF + " SE1.E1_NUMCART,"
	cQry += CRLF + " SE1.E1_HIST,"
	cQry += CRLF + " SE1.E1_NUMLIQ,"
	cQry += CRLF + " SE1.E1_NUMSOL,"
	cQry += CRLF + " SE1.E1_ORIGEM,"
	cQry += CRLF + " SE1.E1_NSUTEF,"
	cQry += CRLF + " SE1.E1_DOCTEF,"
	cQry += CRLF + " SE1.E1_CARTAUT,"
	cQry += CRLF + " SE1.E1_FLAGFAT,"

	//DANILO: Regra que verifica se tem devolucao, trazido para melhorar performance.
	cQry += CRLF + " (SELECT COUNT(*)  "
	cQry += CRLF + " FROM "+RetSqlName("SD1")+" SD1  "
	cQry += CRLF + " WHERE SD1.D_E_L_E_T_	= ' '  "
	cQry += CRLF + " 	AND SD1.D1_FILIAL 	= '"+xFilial("SD1")+"'  "
	cQry += CRLF + " 	AND SD1.D1_TIPO		= 'D'  "
	cQry += CRLF + " 	AND SD1.D1_NFORI	= SE1.E1_NUM  "
	cQry += CRLF + " 	AND SD1.D1_SERIORI	= SE1.E1_PREFIXO  "
	cQry += CRLF + " 	AND SD1.D1_FORNECE	= SE1.E1_CLIENTE  "
	cQry += CRLF + " 	AND SD1.D1_LOJA		= SE1.E1_LOJA  "
	cQry += CRLF + " ) AS QTDDEVOL,  "

	If !lFatConv // Diferente de conveniência
		cQry += CRLF + " SL1.L1_STATUS,"
		cQry += CRLF + " (CASE WHEN SE1.E1_TIPO='NP ' THEN '1'" // Nota a prazo
		cQry += CRLF + " 		WHEN SE1.E1_TIPO='VLS' THEN '2'" // Vale serviço
		cQry += CRLF + " 		WHEN SE1.E1_TIPO='RP ' THEN '3'" // Requisição
		cQry += CRLF + " 		WHEN SE1.E1_TIPO='CF ' THEN '4'" // Carta frete
		cQry += CRLF + " 		ELSE '5'" // Demais tipos
		cQry += CRLF + "  END) AS ORDEM_TP"
	Else
		cQry += " SE1.E1_TIPO AS ORDEM_TP"
	EndIf

	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1		INNER JOIN "+RetSqlName("SED")+" SED 	ON (SED.ED_CODIGO 	= SE1.E1_NATUREZ"
	cQry += CRLF + "																			AND SED.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " 																			AND SED.ED_FILIAL	= '"+xFilial("SED")+"')"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("SF2")+" SF2 	ON (SE1.E1_PREFIXO	= SF2.F2_SERIE"
	cQry += CRLF + " 										 									AND SE1.E1_NUM 		= SF2.F2_DOC"
	cQry += CRLF + " 										 									AND SE1.E1_CLIENTE 	= SF2.F2_CLIENTE"
	cQry += CRLF + " 										 									AND SE1.E1_LOJA 	= SF2.F2_LOJA"
	cQry += CRLF + "																			AND SF2.D_E_L_E_T_	<> '*'"
	//DANILO: colocado filtro no WHERE principal da query
	//If !Empty(cSerieNF)
	//	cQry += CRLF + " 																		AND SF2.F2_SERIE 	IN "+FormatIn(cSerieNF,";")
	//Endif
	cQry += CRLF + " 																			AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"')"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("U88")+" U88 	ON 	(SE1.E1_CLIENTE	= U88.U88_CLIENT"
	cQry += CRLF + " 																			AND SE1.E1_LOJA		= U88.U88_LOJA"
	cQry += CRLF + " 																			AND SE1.E1_TIPO		= U88.U88_FORMAP"
	cQry += CRLF + " 																			AND U88.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " 																			AND U88.U88_FILIAL	= '"+xFilial("U88")+"')"

	cQry += CRLF + " 									INNER JOIN "+RetSqlName("SA1")+" SA1	ON (SE1.E1_CLIENTE	= SA1.A1_COD"
	cQry += CRLF + " 																			AND SE1.E1_LOJA		= SA1.A1_LOJA"
	cQry += CRLF + " 																			AND SA1.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " 																			AND SA1.A1_FILIAL	= '"+xFilial("SA1")+"')"

	If !lFatConv // Diferente de conveniência
		cQry += CRLF + " 									LEFT JOIN "+RetSqlName("UF6")+" UF6		ON (SA1.A1_XCLASSE	= UF6.UF6_CODIGO"
		cQry += CRLF + " 																			AND UF6.D_E_L_E_T_	<> '*'"
		cQry += CRLF + " 																			AND UF6.UF6_FILIAL	= '"+xFilial("UF6")+"')"
	EndIf

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("SE4")+" SE4		ON (SE1.E1_XCOND		= SE4.E4_CODIGO"
	cQry += CRLF + " 																			AND SE4.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " 																			AND SE4.E4_FILIAL	= '"+xFilial("SE4")+"')"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("SA6")+" SA6		ON (SE1.E1_PORTADO	= SA6.A6_COD"
	cQry += CRLF + " 																			AND SE1.E1_AGEDEP	= SA6.A6_AGENCIA"
	cQry += CRLF + " 																			AND SE1.E1_CONTA	= SA6.A6_NUMCON"
	cQry += CRLF + " 																			AND SA6.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " 																			AND SA6.A6_FILIAL	= '"+xFilial("SA6")+"')"

	If !lFatConv // Diferente de conveniência
		cQry += CRLF + " 									LEFT JOIN "+RetSqlName("SL1")+" SL1 	ON (SE1.E1_PREFIXO	= SL1.L1_SERIE"
		cQry += CRLF + " 										 									AND SE1.E1_NUM 		= SL1.L1_DOC"
		cQry += CRLF + " 										 									AND SE1.E1_CLIENTE 	= SL1.L1_CLIENTE"
		cQry += CRLF + " 										 									AND SE1.E1_LOJA 	= SL1.L1_LOJA"
		cQry += CRLF + " 										 									AND SL1.L1_SITUA 	= 'OK'"
		cQry += CRLF + "																			AND SL1.D_E_L_E_T_	<> '*'"
		cQry += CRLF + " 																			AND SL1.L1_FILIAL	= '"+xFilial("SL1")+"')"

		cQry += CRLF + " 									LEFT JOIN "+RetSqlName("U57")+" U57 	ON (SE1.E1_XCODBAR	= U57.U57_PREFIX+U57.U57_CODIGO+U57.U57_PARCEL"
		cQry += CRLF + "																			AND U57.D_E_L_E_T_	<> '*'"
		cQry += CRLF + " 																			AND U57.U57_FILIAL	= '"+xFilial("U57")+"')"
	EndIf

	cQry += CRLF + " WHERE SE1.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1")+"'"
	If !Empty(dGet24)
		cQry += CRLF + " AND SE1.E1_EMISSAO	<= '"+DToS(dGet24)+"'"
	Else
		cQry += CRLF + " AND SE1.E1_EMISSAO	<= '"+DToS(dDataBase)+"'"
	Endif

	cQry += CRLF + " AND (SF2.F2_ESPECIE IS NULL OR SF2.F2_ESPECIE	= 'CF   ' OR SF2.F2_ESPECIE	= 'NFCE ' OR SF2.F2_ESPECIE	= 'SPED ')"

	//considera titulos sem vinculo com nota ou de notas com séries do parametro
	If !Empty(cSerieNF)
		cQry += CRLF + " AND (SF2.F2_SERIE IS NULL OR SF2.F2_SERIE IN "+FormatIn(cSerieNF,";") + ")"
	Endif

	If !lCheckBox6 // Não haver NF relacionada
		If !lCheckBox8 // Não ser indiferente NF
			cQry += CRLF + " AND (SF2.F2_NFCUPOM = ' ' OR SF2.F2_NFCUPOM IS NULL)" //Não possui NF s/Cupom
		Endif
	Endif

//Filtra os títulos importados
	If cModulo <> "TMK" // Origem da chamada for a rotina Telecobrança ou Agenda do Operador

		If !lCB10 // Não considera títulos com prefixo igual a IMP
			cQry += CRLF + " AND SE1.E1_PREFIXO 	<> 'IMP'"
		Endif
	Endif

//Filtra tipos de convenios
	cQry += CRLF + " AND SE1.E1_TIPO		IN "+FormatIN(cTpFat,"/")+""

/****************************************************/
//Abaixo condições em conformidade com o fonte padrão
/****************************************************/

	If !lCheckBox5 // Não haver boleto relacionado

		If lCheckBox7 // Indiferente Bol
			cQry += CRLF + " AND SE1.E1_SITUACA 	IN ('0','F','G','1')" // Carteira, Carteira Protesto, Carteira Acordo e Bordero
		Else
			cQry += CRLF + " AND SE1.E1_SITUACA 	IN ('0','F','G')" // Carteira, Carteira Protesto e Carteira Acordo
		Endif
	Else
		cQry += CRLF + " AND SE1.E1_SITUACA 	IN ('1')" //Bordero
	Endif

	cQry += CRLF + " AND SE1.E1_TIPO 		NOT IN "+FormatIN(MVRECANT+MVPROVIS,,3) // RA+PR

// Filtra para nao exibir os tx's
	cQry += CRLF + " AND SE1.E1_TIPO 		NOT IN "+FormatIN(cImpostos,,3) // Diferente de Impostos

// Verifica integracao com PMS e nao permite FATURAR titulos que tenham solicitacoes
// de transferencias em aberto.
	//cQry += CRLF + " AND SE1.E1_NUMSOL		= ' '"

// Condicao para omitir os titulos de abatimento que tenham o titulo principal em bordero
	cQry += CRLF + " AND SE1.R_E_C_N_O_ NOT IN( "
	cQry += CRLF + " SELECT SE1A.R_E_C_N_O_ "
	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1A "
	cQry += CRLF + " WHERE "
	cQry += CRLF + " SE1A.E1_FILIAL 	= SE1.E1_FILIAL AND "
	cQry += CRLF + " SE1A.E1_NUM 		= SE1.E1_NUM AND "
	cQry += CRLF + " SE1A.E1_PREFIXO 	= SE1.E1_PREFIXO AND "
	cQry += CRLF + " SE1A.E1_PARCELA 	= SE1.E1_PARCELA AND "
	cQry += CRLF + " SE1A.E1_TIPO 		IN "+FormatIN(MVABATIM,"|")+" AND " // AB-|FB-|FC-|FU-|IR-|IN-|IS-|PI-|CF-|CS-|FE-|IV-
	cQry += CRLF + " SE1A.E1_SITUACA 	NOT IN ('0','F','G') AND "
	cQry += CRLF + " SE1A.D_E_L_E_T_ 	= ' ' )"

// Template GEM - nao podem ser faturados os titulos do GEM
	If HasTemplate("LOT")
		cQry += CRLF + " AND E1_NCONTR = ' '"
	EndIf

// Permite a inclusão de uma condicao adicional para a Query
// Esta condicao obrigatoriamente devera ser tratada em um AND ()
// para nao alterar as regras basicas da mesma.
	If lFa280Qry

		cQueryADD := ExecBlock("FA280QRY",.F.,.F.)

		If ValType(cQueryADD) == "C"
			cQry += CRLF + " AND (" + cQueryADD + ")"
		Endif
	Endif
/*****************************************************/
//fim das condições em conformidade com o fonte padrão
/*****************************************************/

	If !Empty(cGet11) .Or. !Empty(cGet12) // Produtos ou Grupos de Produto

		cQry += CRLF + " AND (SF2.F2_DOC + SF2.F2_SERIE + SF2.F2_CLIENTE + SF2.F2_LOJA	IN (SELECT"
		cQry += CRLF + "																	DISTINCT SF2_2.F2_DOC + SF2_2.F2_SERIE + SF2_2.F2_CLIENTE + SF2_2.F2_LOJA"
		cQry += CRLF + "																	FROM "+RetSqlName("SF2")+" SF2_2, "+RetSqlName("SD2")+" SD2"
		cQry += CRLF + "																	WHERE SF2_2.D_E_L_E_T_	<> '*'"
		cQry += CRLF + "																	AND SD2.D_E_L_E_T_		<> '*'"
		cQry += CRLF + " 																	AND SF2_2.F2_FILIAL		= '"+xFilial("SF2")+"'"
		cQry += CRLF + " 																	AND SD2.D2_FILIAL		= '"+xFilial("SD2")+"'"
		cQry += CRLF + "																	AND SF2_2.F2_DOC		= SD2.D2_DOC"
		cQry += CRLF + "																	AND SF2_2.F2_SERIE		= SD2.D2_SERIE"
		cQry += CRLF + "																	AND SF2_2.F2_CLIENTE	= SD2.D2_CLIENTE"
		cQry += CRLF + "																	AND SF2_2.F2_LOJA		= SD2.D2_LOJA"

		If !Empty(cGet11) // Produtos
			cProd := FormatIN(cGet11,"/")
			cQry += CRLF + "																AND SD2.D2_COD			IN "+cProd+""
		Endif

		If !Empty(cGet12) // Grupos de Produto
			cGrpProd := FormatIN(cGet12,"/")
			cQry += CRLF + "																AND SD2.D2_GRUPO		IN "+cGrpProd+""
		Endif

		cQry += CRLF + "																	)"
		cQry += CRLF + " OR SF2.F2_DOC + SF2.F2_SERIE + SF2.F2_CLIENTE + SF2.F2_LOJA IS NULL)"
	Endif

	//DANILO: colocado regra do U88_FILAUT na query para ficar mais rapido
	//Se não encontrar a U88 ou se encontrar, deve ter filial autorizada
	cQry += CRLF + " AND (U88.U88_FILAUT IS NULL OR U88.U88_FILAUT LIKE '%"+cFilAnt+"%') "

	If !Empty(cGet5) // Usuário resp. cliente
		cQry += CRLF + " AND U88.U88_USUFAT = '"+cGet5+"'"
	Endif

	If !Empty(cGet6) // Cliente
		cCli := FormatIN(cGet6,"/")
		//cQry += CRLF + " AND RTRIM(SE1.E1_CLIENTE)+SE1.E1_LOJA IN "+cCli+""
		cQry += CRLF + " AND SE1.E1_CLIENTE+SE1.E1_LOJA IN "+cCli+""
	Endif

	If !Empty(cGet7) // Grupo Cliente
		cGrpCli := FormatIN(cGet7,"/")
		cQry += CRLF + " AND SA1.A1_GRPVEN IN "+cGrpCli+""
	Endif

	if len(Alltrim(xFilial("SE1"))) != len(cFilAnt) //verifico se SE1 é compartilhada e troco o filtro de Segmento por filtro de Filial
		If !Empty(cGet8) // Filiais de Origem
			cFilOrig := FormatIN(cGet8,"/")
			cQry += CRLF + " AND SE1.E1_FILORIG IN "+cFilOrig+""
		Endif
	else
		If !Empty(cGet8) // Segmento Cliente
			cSegCli := FormatIN(cGet8,"/")
			cQry += CRLF + " AND SA1.A1_SATIV1 IN "+cSegCli+""
		Endif
	endif

	If !lFatConv // Diferente de conveniência
		If !Empty(cGet17) // Classe Cliente
			cClasseCli := FormatIN(cGet17,"/")
			cQry += CRLF + " AND SA1.A1_XCLASSE IN "+cClasseCli+""
		Endif
	EndIf

	If !Empty(cGet9) // Condição de Pagamento
		cCond := FormatIN(cGet9,"/")
		cQry += CRLF + " AND SE1.E1_XCOND 	IN "+cCond+""
	Endif

	If !lFatConv // Diferente de conveniência
		If !Empty(cGet18) // Motivo saque
			cMotSaq := FormatIN(cGet18,"/")
			cQry += CRLF + " AND U57.U57_MOTIVO IN "+cMotSaq+""
		Endif
	EndIf

	If !Empty(cGet10) // Forma de Pagamento

		If lCheckBox4
			cFormaPg := "'FT'"
			cQry += CRLF + " AND SE1.E1_TIPO IN ("+cFormaPg+")"
			//cQry += CRLF + " AND EXISTS (SELECT 1 FROM "+RetSqlName("SE1")+" A WHERE A.E1_FILIAL = SE1.E1_FILIAL AND A.E1_NUM = SE1.E1_NUMLIQ AND A.E1_TIPO IN "+FormatIN(cGet10,"/")+")"
			cQry += CRLF + " AND (" //faturas antigas
			cQry += CRLF + "EXISTS (SELECT 1 FROM "+RetSqlName("SE1")+" A WHERE A.D_E_L_E_T_ = ' ' AND A.E1_FILIAL = SE1.E1_FILIAL AND A.E1_FATURA = SE1.E1_NUM AND A.E1_TIPO IN "+FormatIN(cGet10,"/")+")"
			cQry += CRLF + " OR " //liquidação novas
			cQry += CRLF + "EXISTS (SELECT 1 FROM "+RetSqlName("FI7")+" FI7 WHERE FI7.D_E_L_E_T_ = ' ' AND SE1.E1_PREFIXO = FI7.FI7_PRFDES AND SE1.E1_NUM = FI7.FI7_NUMDES AND SE1.E1_PARCELA = FI7.FI7_PARDES AND SE1.E1_TIPO = FI7.FI7_TIPDES AND SE1.E1_CLIENTE = FI7.FI7_CLIDES AND SE1.E1_LOJA = FI7.FI7_LOJDES AND FI7.FI7_TIPORI IN "+FormatIN(cGet10,"/")+")"
			cQry += CRLF + ")"
		Else
			cFormaPg := FormatIN(cGet10,"/")
			cQry += CRLF + " AND SE1.E1_TIPO IN "+cFormaPg+""
		EndIf
	Else
		If lCheckBox4
			cFormaPg := "'FT'"
			cQry += CRLF + " AND SE1.E1_TIPO IN ("+cFormaPg+")"
		EndIf
	Endif

	if cStatusMail == 'E' //enviadoF
		cQry += CRLF + " AND SE1.E1_FLAGFAT = 'E'"
	elseif cStatusMail == 'N' //não enviado
		cQry += CRLF + " AND SE1.E1_FLAGFAT <> 'E'"
	endif

	If !Empty(dGet13) // Dt. Emissão - De
		cQry += CRLF + " AND SE1.E1_EMISSAO >= '"+DToS(dGet13)+"'"
	Endif

	If !Empty(dGet14) // Dt. Emissão - Ate
		cQry += CRLF + " AND SE1.E1_EMISSAO <= '"+DToS(dGet14)+"'"
	Endif

	If !Empty(dGet15) // Dt. Vencto. - De
		cQry += CRLF + " AND SE1.E1_VENCTO >= '"+DToS(dGet15)+"'"
	Endif

	If !Empty(dGet16) // Dt. Vencto. - Ate
		cQry += CRLF + " AND SE1.E1_VENCTO <= '"+DToS(dGet16)+"'"
	Endif

	If !Empty(dGet19) // Dt. fatura - De
		cQry += CRLF + " AND SE1.E1_XDTFATU >= '"+DToS(dGet19)+"'"
	Endif

	If !Empty(dGet20) // Dt. fatura - Ate
		cQry += CRLF + " AND SE1.E1_XDTFATU <= '"+DToS(dGet20)+"'"
	Endif

	If !Empty(cGet21) // Título - De
		cQry += CRLF + " AND SE1.E1_NUM 	>= '"+cGet21+"'"
	Endif

	If !Empty(cGet22) // Título - Ate
		cQry += CRLF + " AND SE1.E1_NUM 	<= '"+cGet22+"'"
	Endif

	If !lFatConv // Diferente de conveniência
		If !Empty(cGet23) // Placa
			cQry += CRLF + " AND SE1.E1_XPLACA = '"+StrTran(cGet23,"-","")+"'"
		Endif
	EndIf

	If lCheckBox1 .And. lCheckBox2 .And. lCheckBox3
		cQry += CRLF + " AND SE1.E1_SALDO = SE1.E1_SALDO"
	ElseIf !lCheckBox1 .And. lCheckBox2 .And. lCheckBox3
		cQry += CRLF + " AND (SE1.E1_SALDO < SE1.E1_VALOR OR SE1.E1_SALDO = 0)"
	ElseIf !lCheckBox1 .And. !lCheckBox2 .And. lCheckBox3
		cQry += CRLF + " AND SE1.E1_SALDO = 0"
	ElseIf !lCheckBox1 .And. lCheckBox2 .And. !lCheckBox3
		cQry += CRLF + " AND (SE1.E1_SALDO > 0 AND SE1.E1_SALDO < SE1.E1_VALOR)"
	ElseIf !lCheckBox1 .And. !lCheckBox2 .And. !lCheckBox3

		aSize(aReg,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg := nil
		aReg := {}
		aadd(aReg, aClone(aLinEmpty))

		oBrw:SetArray(aReg)
		oBrw:bLine := bBrwLine
		oBrw:Refresh()

		oSay2:Refresh() // Contador
		oSay23:Refresh() // Totalizador
		oSay35:Refresh() // Totalizador

		oButton1:lVisible 	:= .F.
		oButton30:lVisible 	:= .F.
		oButton2:lVisible 	:= .T.
		oButton4:lVisible 	:= .T.
		oButton24:lVisible 	:= .T.
		oButton25:lVisible 	:= .T.
		oSay25:lVisible 	:= .T.
		oButton27:lVisible 	:= .T.
		oButton5:lVisible 	:= .T.
		If lGeraNF
			oButton6:lVisible 	:= .T.
		Endif

		MsgInfo("Nenhum registro selecionado. Obrigatoriamente deve ser selecionada uma situação do título.","Atenção")
		Return
	ElseIf lCheckBox1 .And. !lCheckBox2 .And. !lCheckBox3
		cQry += CRLF + " AND SE1.E1_SALDO > 0"
	ElseIf lCheckBox1 .And. !lCheckBox2 .And. lCheckBox3
		cQry += CRLF + " AND ((SE1.E1_SALDO > 0 AND SE1.E1_SALDO = SE1.E1_VALOR) OR SE1.E1_SALDO = 0)"
	ElseIf lCheckBox1 .And. lCheckBox2 .And. !lCheckBox3
		//-- comentado, pois para este caso: SALDO maior que zero é VALIDO (melhora o desenpenho da consulta no banco)
		cQry += CRLF + " AND SE1.E1_SALDO > 0"	//cQry += CRLF + " AND (SE1.E1_SALDO > 0 OR (SE1.E1_SALDO > 0 AND SE1.E1_SALDO < SE1.E1_VALOR))"
	Endif

	//limitar a consulta: Tratamento realizado para evitar Reference counter overflow.
	If cDBMS == 'DB2'
		cQry := "SELECT "+ cQry + " FETCH FIRST " + STR(GRIDMAXLIN) + " ROWS ONLY"
	ElseIf cDBMS == 'INFORMIX'
		cQry := "SELECT FIRST " + STR(GRIDMAXLIN) + " " + cQry
	ElseIf cDBMS == 'ORACLE'
		cQry := "SELECT "+ cQry + " AND ROWNUM <= " + STR(GRIDMAXLIN) + ""
	ElseIf cDBMS == 'MYSQL'
		cQry := "SELECT "+ cQry + " AND LIMIT " + STR(GRIDMAXLIN) + ""
	ElseIf cDBMS == 'POSTGRES'
		cQry := "SELECT "+ cQry + " LIMIT " + STR(GRIDMAXLIN) + ""
	Else
		cQry := "SELECT TOP " + STR(GRIDMAXLIN) + " " + cQry
	EndIf

	cQry += CRLF + " ORDER BY ORDEM_TP,SA1.A1_NOME,SE1.E1_PREFIXO,SE1.E1_NUM,SE1.E1_PARCELA"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETE017.txt",cQry)
	TcQuery cQry NEW Alias "QRYFAT"

	nCont1 := 0
	nCont2 := 0
	QRYFAT->(dbEval({|| nCont1++}))
	ProcRegua(nCont1+1)
	IncProc()

	If lEnd
		Return
	EndIf

	QRYFAT->(dbGoTop())

	If QRYFAT->(!EOF())

		//oSay:cCaption := "Realizando a consulta..."
		//ProcessMessages()

		aContent := FWGetSX5('05') // Vetor com os dados do SX5 com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO

		//DbSelectArea("U88")
		//U88->(DbSetOrder(1)) // U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA

		While QRYFAT->(!EOF())

			//verifico valor acessorios
			SE1->(DbGoTo(QRYFAT->RECNO))
			nCont2++
			IncProc("Carregando título "+cValToChar(nCont2)+" de "+cValToChar(nCont1)+"...")

			If lEnd
				Return
			EndIf

			// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
			//DANILO: comentado aqui, e adicionado da query, para melhorar performance.
			/*If U88->(DbSeek(xFilial("U88")+QRYFAT->E1_TIPO+Space(6 - Len(QRYFAT->E1_TIPO))+QRYFAT->E1_CLIENTE+QRYFAT->E1_LOJA))
				If !cFilAnt $ U88->U88_FILAUT
					QRYFAT->(DbSkip())
					Loop
				Endif
			Endif*/

			If AllTrim(QRYFAT->E1_TIPO) == "FT" // Fatura

				If !lCheckBox6 // Não haver NF relacionada

					If !lCheckBox8 // Não ser indiferente NF

						If PesqNfCf(cFilAnt,QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,QRYFAT->E1_TIPO)
							QRYFAT->(DbSkip())
							Loop
						Endif
					Endif
				Else
					If !PesqNfCf(cFilAnt,QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,QRYFAT->E1_TIPO)
						QRYFAT->(DbSkip())
						Loop
					Endif
				Endif
			Endif

			/* DANILO: comentado, pois ja existe o filtro na query
			If !lFatConv // Diferente de conveniência
				//Somente séries definidas
				cSerVd := RetSerVd(QRYFAT->E1_NUM,QRYFAT->E1_PREFIXO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA)
				If !Empty(cSerVd)
					If !AllTrim(cSerVd) $ cSerieNF
						QRYFAT->(dbSkip())
						Loop
					Endif
				Endif
			EndIf */

			// Conferência de caixa habilitada
			If lConfCx
				If PesqCxAbe(QRYFAT->RECNO)
					QRYFAT->(DbSkip())
					Loop
				Endif
			Endif

			// Desconsidera caso conste numa Nota de Devolução
			//DANILO: levado busca devolucao para query principal, para melhorar performance
			//If TemDev(cFilAnt,QRYFAT->E1_NUM,QRYFAT->E1_PREFIXO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA)
			if QRYFAT->QTDDEVOL > 0
				QRYFAT->(DbSkip())
				Loop
			Endif

			// desconsidera caso tenha venda duplicada (não devolvida)
			SE1->(DbGoTo(QRYFAT->RECNO))
			If lValDupl .and. ValDuplic()
				QRYFAT->(DbSkip())
				Loop
			EndIf

			// Legenda
			If !lFatConv // Diferente de conveniência

				Do Case
				Case QRYFAT->L1_STATUS $ cNFRecu
					oLeg := oAmarelo
				Case QRYFAT->E1_SALDO == 0
					oLeg := oVermelho
				Case QRYFAT->E1_VALOR > QRYFAT->E1_SALDO .And. QRYFAT->E1_SALDO > 0
					oLeg := oAzul
				Case AllTrim(QRYFAT->E1_TIPO) = 'FT'
					oLeg := oMarrom
				OtherWise
					oLeg := oVerde
				EndCase
			Else
				Do Case
				Case QRYFAT->E1_SALDO == 0
					oLeg := oVermelho
				Case QRYFAT->E1_VALOR > QRYFAT->E1_SALDO .And. QRYFAT->E1_SALDO > 0
					oLeg := oAzul
				Case AllTrim(QRYFAT->E1_TIPO) = 'FT'
					oLeg := oMarrom
				OtherWise
					oLeg := oVerde
				EndCase
			EndIf

			cTpTit := Space(55)
			If Len(aContent)>0 // SX5->(DbSeek(xFilial("SX5")+"05"+QRYFAT->E1_TIPO))
				nPosX5 := aScan(aContent, {|x| Alltrim(x[3])==Alltrim(QRYFAT->E1_TIPO) })
				if nPosX5 > 0
					cTpTit := aContent[nPosX5][4] //SX5->X5_DESCRI
				endif
			Endif

			nVlrAcess := U_UFValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1/*nMoeda*/,SE1->E1_TXMOEDA)

			aLinAux := aClone(aLinEmpty)
			aLinAux[nPosLegend] := oLeg
			aLinAux[nPosFilial] := QRYFAT->E1_FILIAL
			if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
				aLinAux[nPosFilOri] := QRYFAT->E1_FILORIG
			endif
			aLinAux[nPosTipo] := QRYFAT->E1_TIPO
			aLinAux[nPosOriFat] := IIF(AllTrim(QRYFAT->E1_TIPO) == "FT",OrigFatur(QRYFAT->E1_FILIAL,QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,QRYFAT->E1_TIPO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA),"")
			aLinAux[nPosDescri] := AllTrim(cTpTit)
			aLinAux[nPosPrefixo] := QRYFAT->E1_PREFIXO
			aLinAux[nPosNumero] := QRYFAT->E1_NUM
			aLinAux[nPosParcela] := QRYFAT->E1_PARCELA
			aLinAux[nPosNaturez] := AllTrim(QRYFAT->ED_DESCRIC)
			aLinAux[nPosPortado] := QRYFAT->E1_PORTADO
			aLinAux[nPosDeposit] := QRYFAT->E1_AGEDEP
			aLinAux[nPosNConta] := QRYFAT->E1_CONTA
			aLinAux[nPosBanco] := AllTrim(QRYFAT->A6_NOME)
			if !lFatConv
				aLinAux[nPosPlaca] := Transform(QRYFAT->E1_XPLACA,"@!R NNN-9N99")
			endif
			aLinAux[nPosCliente] := QRYFAT->E1_CLIENTE
			aLinAux[nPosLoja] := QRYFAT->E1_LOJA
			aLinAux[nPosNome] := AllTrim(QRYFAT->A1_NOME)
			aLinAux[nPosCGC] := iif(len(AllTrim(QRYFAT->A1_CGC))==11,Transform(AllTrim(QRYFAT->A1_CGC),"@R 999.999.999-99"),Transform(AllTrim(QRYFAT->A1_CGC),"@R 99.999.999/9999-99"))
			if SA1->(FieldPos("A1_XOBSFAT")) > 0
				cObsFatCli := Alltrim(StrTran(Posicione("SA1",1,xFilial("SA1",QRYFAT->E1_FILORIG)+QRYFAT->E1_CLIENTE+QRYFAT->E1_LOJA,"A1_XOBSFAT"),Chr(13)+Chr(10)," "))
				aLinAux[nPosObsFat] := SubStr(cObsFatCli,1,30) + iif(len(cObsFatCli)>30,"...","")
			endif
			if !lFatConv
				aLinAux[nPosClasse] := AllTrim(QRYFAT->UF6_DESC)
			endif
			aLinAux[nPosCondPg] := AllTrim(QRYFAT->E4_DESCRI)
			aLinAux[nPosEmissao] := DToC(SToD(QRYFAT->E1_EMISSAO))
			aLinAux[nPosVencto] := DToC(SToD(QRYFAT->E1_VENCTO))
			aLinAux[nPosValor] := Transform(IIF(QRYFAT->E1_VLRREAL > 0 .And. QRYFAT->E1_VLRREAL <> QRYFAT->E1_VALOR,QRYFAT->E1_VLRREAL,QRYFAT->E1_VALOR),"@E 9,999,999,999,999.99")
			aLinAux[nPosSaldo] := Transform(QRYFAT->E1_SALDO,"@E 9,999,999,999,999.99")
			aLinAux[nPosDescont] := Transform(QRYFAT->E1_DESCONT,"@E 9,999,999,999,999.99")
			aLinAux[nPosMulta] := Transform(QRYFAT->E1_MULTA,"@E 9,999,999,999,999.99")
			aLinAux[nPosJuros] := Transform(QRYFAT->E1_JUROS,"@E 9,999,999,999,999.99")
			aLinAux[nPosAcresc] := Transform(QRYFAT->E1_ACRESC,"@E 9,999,999,999,999.99")
			aLinAux[nPosDecres] := Transform(QRYFAT->E1_DECRESC,"@E 9,999,999,999,999.99")
			aLinAux[nPosVlAcess] := Transform(nVlrAcess,"@E 9,999,999,999,999.99")
			aLinAux[nPosFatura] := IIF(AllTrim(QRYFAT->E1_TIPO) == "FT",QRYFAT->E1_NUMLIQ,BuscaFT(QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,QRYFAT->E1_TIPO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA))
			aLinAux[nPosRecno] := QRYFAT->RECNO

			if !lFatConv
				cNumCFrete := QRYFAT->E1_NUMCART
				cNumSolE6 := QRYFAT->E1_NUMSOL
				if Alltrim(QRYFAT->E1_ORIGEM) =="FINA630"
					cNumSolE6 := Posicione("SE6",4,QRYFAT->E1_FILIAL + QRYFAT->E1_PREFIXO + QRYFAT->E1_NUM + QRYFAT->E1_PARCELA + QRYFAT->E1_TIPO, "E6_NUMSOL") + "-DESTINO"
				elseif !empty(cNumSolE6)
					cNumSolE6 += "-ORIGEM"
				endif

				aLinAux[nPosMotiv] := QRYFAT->U57_MOTIVO
				aLinAux[nPosProdOs] := iif(SE1->(FieldPos("E1_XPRDOS")) > 0,QRYFAT->E1_XPRDOS,"")
				aLinAux[nPosNCFret] := cNumCFrete
				aLinAux[nPosNMutuo] := cNumSolE6
				aLinAux[nPosNsuTef] := QRYFAT->E1_NSUTEF
				aLinAux[nPosDocTef] := QRYFAT->E1_DOCTEF
				aLinAux[nPosCartAu] := QRYFAT->E1_CARTAUT
				aLinAux[nPosMailFat] := iif(QRYFAT->E1_FLAGFAT=="E","Sim","Não")
				
			endif

			AAdd(aReg, aLinAux)

			QRYFAT->(DbSkip())
		EndDo
	Else
		aSize(aReg,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg := nil
		aReg := {}
		aadd(aReg, aClone(aLinEmpty))
	Endif

	If Len(aReg) == 0
		aSize(aReg,0) //Tratamento realizado para evitar Reference counter overflow.
		aReg := nil
		aReg := {}
		aadd(aReg, aClone(aLinEmpty))
	Endif

	oBrw:SetArray(aReg)
	oBrw:bLine := bBrwLine
	oBrw:nAt := 1
	oBrw:Refresh()

	oSay2:Refresh() // Contador
	oSay23:Refresh() // Totalizador
	oSay35:Refresh() // Totalizador

	If Select("QRYCX") > 0
		QRYCX->(dbCloseArea())
	Endif

	If Select("QRYFAT") > 0
		QRYFAT->(dbCloseArea())
	Endif

	oButton1:lVisible 	:= .F.
	oButton30:lVisible 	:= .F.
	oButton2:lVisible 	:= .T.
	oButton4:lVisible 	:= .T.
	oButton24:lVisible 	:= .T.
	oButton25:lVisible 	:= .T.
	oSay25:lVisible 	:= .T.
	oButton27:lVisible 	:= .T.
	oButton5:lVisible 	:= .T.
	If lGeraNF
		oButton6:lVisible 	:= .T.
	Endif

	oBrw:SetFocus()

//Garantir liberaçao de locks
	DbCommitAll()
	MsUnlockAll()

Return

/***************************/
Static Function FilCli(cCod)
/***************************/

	FWMsgRun(,{|oSay| cGet6 := U_UMultSel("Clientes","SA1","A1_COD,A1_LOJA,A1_NOME,A1_CGC","A1_NOME,A1_COD,A1_LOJA","A1_MSBLQL <> '1'" + iif(Empty(AllTrim(cCod)),""," AND ( A1_COD = '"+AllTrim(cCod)+"' OR A1_NOME LIKE '%"+Upper(AllTrim(cCod))+"%' )"),cGet6, "/")},'Aguarde','Selecionando registros...')
	oGet6:Refresh()

Return

/**************************/
Static Function FilGrpCli()
/**************************/

	FWMsgRun(,{|oSay| cGet7 := U_UMultSel("Grupos de Cliente","ACY","ACY_GRPVEN,ACY_DESCRI","ACY_DESCRI",,cGet7,"/")},'Aguarde','Selecionando registros...')
	oGet7:Refresh()

Return

/**************************/
Static Function FilSegCli()
/**************************/

	FWMsgRun(,{|oSay| cGet8 := U_UMultSel("Segmentos","SX5","X5_CHAVE,X5_DESCRI","X5_DESCRI","X5_TABELA = 'T3'",cGet8,"/")},'Aguarde','Selecionando registros...')
	oGet8:Refresh()

Return

/**************************/
Static Function FilFilialOri()
/**************************/
	
	FWMsgRun(,{|oSay| cGet8 := SM0MultiSel() },'Aguarde','Selecionando registros...')
	oGet8:Refresh()

Return

/**************************/
Static Function FilClaCli()
/**************************/

	FWMsgRun(,{|oSay| cGet17 := U_UMultSel("Classe Cliente","UF6","UF6_CODIGO,UF6_DESC","UF6_DESC",,cGet17,"/")},'Aguarde','Selecionando registros...')
	oGet17:Refresh()

Return

/************************/
Static Function FilCond()
/************************/

	FWMsgRun(,{|oSay| cGet9 := U_UMultSel("Condição de Pagamento","SE4","E4_CODIGO,E4_DESCRI","E4_DESCRI",,cGet9,"/")},'Aguarde','Selecionando registros...')
	oGet9:Refresh()

Return

/**************************/
Static Function FilMotSaq()
/**************************/

	FWMsgRun(,{|oSay| cGet18 := U_UMultSel("Motivos de Saque","SX5","X5_CHAVE,X5_DESCRI","X5_DESCRI","X5_TABELA = 'UX'",cGet18,"/")},'Aguarde','Selecionando registros...')
	oGet18:Refresh()

Return

/***************************/
Static Function FilFormaPg()
/***************************/

	FWMsgRun(,{|oSay| cGet10 := U_UMultSel("Formas de Pagamento","SX5","X5_CHAVE,X5_DESCRI","X5_DESCRI","X5_TABELA = '24' AND X5_CHAVE IN "+FormatIN(cTpFat,"/")+"",cGet10,"/")},'Aguarde','Selecionando registros...')
	oGet10:Refresh()

Return

/************************/
Static Function FilProd()
/************************/

	FWMsgRun(,{|oSay| cGet11 := U_UMultSel("Produtos","SB1","B1_COD,B1_DESC","B1_DESC","B1_MSBLQL <> '1' AND B1_GRUPO IN "+FormatIN(GetMv("MV_COMBUS"),"/")+"",cGet11,"/")},'Aguarde','Selecionando registros...')
	oGet11:Refresh()

Return

/***************************/
Static Function FilGrpProd()
/***************************/

	FWMsgRun(,{|oSay| cGet12 := U_UMultSel("Grupos de Produto","SBM","BM_GRUPO,BM_DESC","BM_DESC",/*"BM_GRUPO IN "+FormatIN(GetMv("MV_COMBUS"),"/")+""*/,cGet12,"/")},'Aguarde','Selecionando registros...')
	oGet12:Refresh()

Return

/************************/
Static Function MarkReg()
/************************/
	
	if nPosObsFat<> Nil .AND. nPosObsFat > 0 .AND. oBrw:nColPos == nPosObsFat .AND. !empty(aReg[oBrw:nAT][nPosObsFat])
		ObsCliente(aReg[oBrw:nAT][nPosCliente],aReg[oBrw:nAT][nPosLoja])
		Return
	endif

	If !Empty(aReg[oBrw:nAT][nPosTipo]) // Tipo/Registro válido

		If aReg[oBrw:nAT][nPosMark]

			aReg[oBrw:nAT][nPosMark] := .F.
			nCont--

			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",",".")) > 0
				nTotBrut -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",","."))
			Endif

			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosSaldo],".",""),",",".")) > 0
				nTotLiq -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosSaldo],".",""),",","."))

				//add Danilo, para considerar acrescimos e decrescimos dos titulos
				If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosAcresc],".",""),",",".")) > 0 //acrescimos
					nTotLiq -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosAcresc],".",""),",","."))
				Endif
				If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosDecres],".",""),",",".")) > 0 //decrescimos
					nTotLiq += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosDecres],".",""),",","."))
				Endif
				If Abs(Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlAcess],".",""),",","."))) > 0 //Valores acessórios
					nTotLiq -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlAcess],".",""),",","."))
				Endif
			Endif
		Else
			aReg[oBrw:nAT][nPosMark] := .T.
			nCont++

			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",",".")) > 0
				nTotBrut += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosValor],".",""),",","."))
			Endif

			If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosSaldo],".",""),",",".")) > 0
				nTotLiq += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosSaldo],".",""),",","."))
				
				//add Danilo, para considerar acrescimos e decrescimos dos titulos
				If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosAcresc],".",""),",",".")) > 0 //acrescimos
					nTotLiq += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosAcresc],".",""),",","."))
				Endif
				If Val(StrTran(StrTran(aReg[oBrw:nAT][nPosDecres],".",""),",",".")) > 0 //decrescimos
					nTotLiq -= Val(StrTran(StrTran(aReg[oBrw:nAT][nPosDecres],".",""),",","."))
				Endif
				If Abs(Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlAcess],".",""),",","."))) > 0 //Valores acessórios
					nTotLiq += Val(StrTran(StrTran(aReg[oBrw:nAT][nPosVlAcess],".",""),",","."))
				Endif
			Endif

		Endif
	Endif

	oBrw:Refresh()
	oSay2:Refresh()
	oSay23:Refresh()
	oSay35:Refresh()

Return

/***************************/
Static Function MarkAllReg()
/***************************/

	Local nI

	nCont		:= 0
	nTotBrut  	:= 0
	nTotLiq  	:= 0

	If !Empty(aReg[oBrw:nAT][nPosTipo]) // Tipo/Registro válido

		If aReg[oBrw:nAT][nPosMark]

			For nI := 1 To Len(aReg)
				aReg[nI][nPosMark] := .F.
			Next
		Else

			For nI := 1 To Len(aReg)

				aReg[nI][nPosMark] := .T.
				nCont++

				If Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",",".")) > 0
					nTotBrut += Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",","."))
				Endif

				If Val(StrTran(StrTran(aReg[nI][nPosSaldo],".",""),",",".")) > 0
					nTotLiq += Val(StrTran(StrTran(aReg[nI][nPosSaldo],".",""),",","."))
					
					//add Danilo, para considerar acrescimos e decrescimos dos titulos
					If Val(StrTran(StrTran(aReg[nI][nPosAcresc],".",""),",",".")) > 0 //acrescimos
						nTotLiq += Val(StrTran(StrTran(aReg[nI][nPosAcresc],".",""),",","."))
					Endif
					If Val(StrTran(StrTran(aReg[nI][nPosDecres],".",""),",",".")) > 0 //decrescimos
						nTotLiq -= Val(StrTran(StrTran(aReg[nI][nPosDecres],".",""),",","."))
					Endif
					If Abs(Val(StrTran(StrTran(aReg[nI][nPosVlAcess],".",""),",","."))) > 0 //Valores acessórios
						nTotLiq += Val(StrTran(StrTran(aReg[nI][nPosVlAcess],".",""),",","."))
					Endif
				Endif
			Next
		Endif
	Endif

	oBrw:Refresh()
	oSay2:Refresh()
	oSay23:Refresh()
	oSay35:Refresh()

Return

/****************************/
Static Function Faturar(oSay, lFatFlex, lAltVenc)
/****************************/

	Local aFatura 		:= {}
	Local aAuxFat		:= {}
	Local nAuxFat		:= 0

	Local lAux			:= .T.

	Local nCont			:= 0

	Local aCliente		:= {}
	Local aGrpProd 		:= {}
	Local aProd			:= {}

	Local lRestGrp		:= .F.
	Local lRestPrd		:= .F.
	Local lSepFpg		:= .F.
	Local lSepMot		:= .F.
	Local lSepOrd		:= .F.

	Local aTit			:= {}

	Local aTmpCli 		:= {}
	Local aTmpSepFp		:= {}
	Local aTmpSepMt		:= {}
	Local aTmpSepOs		:= {}
	Local aTmpGrp		:= {}
	Local aTmpProd		:= {}

	Local lAchou		:= .F.

	Local nImpFatur		:= 0
	Local lImpFatur		:= .F.
	Local nGerBol		:= 0
	Local lGerBol		:= .F.
	Local nImpBol		:= 0
	Local lImpBol		:= .F.
	Local nGeraNfe		:= 0
	Local lGeraNFe		:= .F.
	Local nAuxNfe		:= 0

	Local lFatFat		:= .F.
	Local lCliDif		:= .F.
	Local cCli			:= ""
	Local cLojaCli		:= ""

	Local nI
	Local nK
	Local nL
	Local nM
	Local nX
	Local nJ
	Local nQtdFat

	Local cGrpOri		:= ""
	Local cGrpDest		:= ""
	Local cProdOri		:= ""
	Local cProdDest		:= ""

	Local lOkNfe

	Local lAltDt		:= .F.
	Local dDtBkp		:= CToD("")

	Local lDifCartao	:= .F.
	Local cBandSAE		:= ""
	Local lBandDif		:= .F.
	Local cOperSAE		:= ""
	Local lOperDif		:= .F.

	Local nContAux		:= 0
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cFilFatura	:= ""
	Local nNroTen		:= SuperGetMv("MV_XNROTEN",.F.,3)
	Local cBlFuncBol
	Local cBlFuncFat
	Local lFatNatOr		:= SuperGetMv("MV_XFTNATO",,.F.) //define se a fatura irá assuimir a mesma natureza dos titulos origem
	Local dDtVenFlx		:= stod("")
	Local aCpoComp		:= {}

	Private lFluxoFAT	:= .T. //Variavel para indicar que está no fluxo de faturamento (usada no boleto Decio)
	
	Default lFatFlex := .F.

	DbSelectArea("U88")
	U88->(dbSetOrder(1)) // U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA

	DbSelectArea("SA1")
	SA1->(dbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD

	DbSelectArea("SD2")
	SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM

	If dGet24 <> dDataBase // Dt. referência diferente da Data atual
		dDtBkp		:= dDataBase
		dDataBase 	:= dGet24
		lAltDt 		:= .T.
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

//Verifica se é fatura de fatura
	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T. // Título selecionado

			If Val(StrTran(StrTran(cValToChar(aReg[nI][nPosSaldo]),".",""),",",".")) == 0 // Título baixado

				MsgInfo("O Título ["+AllTrim(aReg[nI][nPosNumero])+"] não se encontra em aberto, operação não permitida.","Atenção")

				If lAltDt
					dDataBase := dDtBkp
				Endif

				Return
			Endif

			If AllTrim(aReg[nI][nPosTipo]) == "FT"

				If Empty(cCli)

					cCli 		:= aReg[nI][nPosCliente]
					cLojaCli 	:= aReg[nI][nPosLoja]
				Else
					If cCli <> aReg[nI][nPosCliente] .Or. cLojaCli <> aReg[nI][nPosLoja]
						lCliDif := .T.
					Endif
				Endif

				//If !AllTrim(aReg[nI][nPosOriFat]) $ "CC/FT/CD/FT/CDP/FT/CCP/FT"
				If !("CC" $ aReg[nI][nPosOriFat] .OR. "CD" $ aReg[nI][nPosOriFat] .OR. "PX" $ aReg[nI][nPosOriFat])
					lDifCartao := .T.
				Endif

				If Empty(cBandSAE)
					cBandSAE := Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_ADMCART")
				Else
					If cBandSAE <> Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_ADMCART")
						lBandDif := .T.
					Endif
				Endif

				If Empty(cOperSAE)
					cOperSAE := Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_REDEAUT")
				Else
					If cOperSAE <> Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_REDEAUT")
						lOperDif := .T.
					Endif
				Endif

				lFatFat := .T.
			else
				If !("CC" $ AllTrim(aReg[nI][nPosTipo]) .OR. "CD" $ AllTrim(aReg[nI][nPosTipo]) .OR. "PX" $ AllTrim(aReg[nI][nPosTipo]))
					lDifCartao := .T.
				Endif
			Endif
		Endif
	Next nI

	If lFatFat .And. (lBandDif .Or. lOperDif) .And. !lDifCartao

		MsgInfo("Em caso de Faturamento de Faturas de Cartão/Pix, os títulos obrigatoriamente devem possuir a mesma Bandeira e Operadora.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	ElseIf lFatFat .And. lCliDif .And. lDifCartao

		MsgInfo("Em caso de Faturamento de Faturas, os títulos obrigatoriamente devem pertencer a um mesmo Cliente e Loja.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	ElseIf !lFatFat .And. lCliDif

		MsgInfo("Obrigatoriamente os títulos devem pertencer a um mesmo Cliente e Loja.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

	If PesqBol()

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

	If !lFatFat

		For nI := 1 To Len(aReg)

			lRestGrp 	:= .F.
			lRestPrd 	:= .F.
			lSepFpg		:= .F.
			lSepMot		:= .F.
			lSepOrd		:= .F.

			If aReg[nI][nPosMark] == .T. // Título selecionado

				nCont++

				// Individualiza clientes
				If Len(aCliente) > 0
					If aScan(aCliente,{|x| x[1] == aReg[nI][nPosCliente] .And. x[2] == aReg[nI][nPosLoja]}) == 0
						AAdd(aCliente,{aReg[nI][nPosCliente],aReg[nI][nPosLoja]})
					Endif
				Else
					AAdd(aCliente,{aReg[nI][nPosCliente],aReg[nI][nPosLoja]})
				Endif

				// Características de Faturamento
				If SA1->(DbSeek(xFilial("SA1")+aReg[nI][nPosCliente]+aReg[nI][nPosLoja]))

					// Validação quanto a restrição de Grupos de Produto/Produtos
					If !Empty(SA1->A1_XRESTGP) .And. IIF(SA1->(FieldPos("A1_XNSEPAR") > 0),SA1->A1_XNSEPAR <> "S",.T.) //Possui restrição e não desconsidera a restrição para separação de faturas
						aGrpProd := StrTokArr(AllTrim(SA1->A1_XRESTGP),"/")
					Endif

					If!Empty(SA1->A1_XRESTPR) .And. IIF(SA1->(FieldPos("A1_XNSEPAR") > 0),SA1->A1_XNSEPAR <> "S",.T.) //Possui restrição e não desconsidera a restrição para separação de faturas
						aProd := StrTokArr(AllTrim(SA1->A1_XRESTPR),"/")
					Endif

					// Verifica Separações
					if lFatNatOr
						lSepFpg := .T.
					else
						If SA1->A1_XSEPFPG == "S" //Individualiza fatura por forma de pagamento
							lSepFpg := .T.
						Else
							lSepFpg := .F.
						Endif
					endif

					If !lFatConv // Diferente de conveniência
					
						If SA1->A1_XSEPMOT == "S" //Individualiza fatura por Motivo de saque
							lSepMot := .T.
						Else
							lSepMot := .F.
						Endif

						If SA1->A1_XSEPORD == "S" //Individualiza fatura por Ordem de serviço
							lSepOrd := .T.
						Else
							lSepOrd := .F.
						Endif
					EndIf
				Endif

				// Restrição quanto ao Grupo de Produto
				SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
				SD2->(DbGoTop())
				SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
				SB1->(DbGoTop())
				If SD2->(DbSeek(xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aReg[nI][nPosNumero]+aReg[nI][nPosPrefixo]+aReg[nI][nPosCliente]+aReg[nI][nPosLoja])) //Exclusivo
					While SD2->(!EOF()) .And. SD2->D2_FILIAL == xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)]) .And. SD2->D2_DOC == aReg[nI][nPosNumero] .And.;
							SD2->D2_SERIE == aReg[nI][nPosPrefixo] .And. SD2->D2_CLIENTE == aReg[nI][nPosCliente] .And. SD2->D2_LOJA == aReg[nI][nPosLoja]
						
						If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
							If aScan(aGrpProd,{|x| x == SB1->B1_GRUPO}) > 0

								lRestGrp := .T.
								Exit
							Endif
						Endif

						SD2->(DbSkip())
					EndDo
				Endif

				// Restrição quanto ao Produto
				SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
				SD2->(DbGoTop())
				If SD2->(DbSeek(xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aReg[nI][nPosNumero]+aReg[nI][nPosPrefixo]+aReg[nI][nPosCliente]+aReg[nI][nPosLoja]))
					While SD2->(!EOF()) .And. SD2->D2_FILIAL == xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)]) .And. SD2->D2_DOC == aReg[nI][nPosNumero] .And.;
							SD2->D2_SERIE == aReg[nI][nPosPrefixo] .And. SD2->D2_CLIENTE == aReg[nI][nPosCliente] .And. SD2->D2_LOJA == aReg[nI][nPosLoja]

						If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
							If aScan(aProd,{|x| AllTrim(x) == AllTrim(SD2->D2_COD)}) > 0
								lRestPrd := .T.
								Exit
							Endif
						Endif

						SD2->(DbSkip())
					EndDo
				Endif

				If !lFatConv // Diferente de conveniência
					lSepMot := lSepMot .And. !IfVaziaS({aReg[nI]}) //Separa [Motivo de Saque] e possui informação de saque
					lSepOrd := lSepOrd .And. !IfVaziaO({aReg[nI]}) //Separa [Ordem de Serviço] e possui ordem de serviço
				EndIf
				lRestGrp := lRestGrp .And. !RetRpVls({aReg[nI]}) //Há restrição por [Grupo de Produto] e não se trata de um agrupamento de requisições ou vale
				lRestPrd := lRestPrd .And. !RetRpVls({aReg[nI]}) //Há restrição por [Produto] e não se trata de um agrupamento de requisições ou vale

				AAdd(aTit,{aReg[nI],;
					lSepFpg,;  //Separação por [Forma de Pagamento]
				lSepMot,;  //Separação por [Motivo de Saque]
				lSepOrd,;  //Separação por [Ordem de Serviço]
				lRestGrp,; //Restrição por [Grupo de Produto]
				lRestPrd}) //Restrição por [Produto]

			Endif
		Next nI
	Else

		For nI := 1 To Len(aReg)

			If aReg[nI][nPosMark] == .T. // Título selecionado

				nCont++

				AAdd(aTit,aReg[nI])
			Endif
		Next nI
	Endif

	If lAux .And. nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	if lAux .AND. lAltVenc
		lAltVenc := TelaVenc(@dDtVenFlx)
		if lAltVenc
			aAdd(aCpoComp , {"E1_VENCTO"	, dDtVenFlx , NIL}) //data vencimento fatura
		else
			lAux := .F.
		endif
	endif

	If lAux
		
		If lAltVenc .OR. MsgYesNo("Haverá o faturamento dos registros selecionados, deseja continuar?")

			If !lFatFat

				For nI := 1 To Len(aCliente)

					aTmpCli 	:= {}
					aTmpSepFp	:= {}
					aTmpSepMt	:= {}
					aTmpSepOs	:= {}
					aTmpGrp		:= {}
					aTmpProd	:= {}

					// Agrupa os títulos por cliente
					For nJ := 1 To Len(aTit)

						If aCliente[nI][1] == aTit[nJ][1][nPosCliente] .And. aCliente[nI][2] == aTit[nJ][1][nPosLoja]

							If Len(aTmpCli) > 0

								lAchou :=  .F.

								For nK := 1 To Len(aTmpCli)

									For nL := 1 To Len(aTmpCli[nK][1])

										If aCliente[nI][1] == aTmpCli[nK][1][nL][nPosCliente] .And. aCliente[nI][2] == aTmpCli[nK][1][nL][nPosLoja] ;
												.And. aTmpCli[nK][2] == aTit[nJ][2] ; //lSepFpg
											.And. aTmpCli[nK][3] == aTit[nJ][3] ; //lSepMot
											.And. aTmpCli[nK][4] == aTit[nJ][4] ; //lSepOrd
											.And. aTmpCli[nK][5] == aTit[nJ][5] ; //lRestGrp
											.And. aTmpCli[nK][6] == aTit[nJ][6]	  //lRestPrd

											lAchou := .T.
											AAdd(aTmpCli[nK][1],aTit[nJ][1])
											Exit
										Endif
									Next nL

									If lAchou
										Exit
									Endif
								Next nK

								If !lAchou

									AAdd(aTmpCli,{{aTit[nJ][1]},aTit[nJ][2],aTit[nJ][3],aTit[nJ][4],aTit[nJ][5],aTit[nJ][6]})
								Endif
							Else
								AAdd(aTmpCli,{{aTit[nJ][1]},aTit[nJ][2],aTit[nJ][3],aTit[nJ][4],aTit[nJ][5],aTit[nJ][6]})
							Endif
						Endif
					Next nJ

					// Não há títulos relacionados ao cliente posicionado
					If Len(aTmpCli) == 0
						Loop
					Endif

					// Verifica se há separação por forma de pagamento
					For nJ := 1 To Len(aTmpCli)

						If aTmpCli[nJ][2] // Separa forma de pagamento

							For nK := 1 To Len(aTmpCli[nJ][1])

								If Len(aTmpSepFp) > 0

									lAchou :=  .F.

									For nL := 1 To Len(aTmpSepFp)

										For nM := 1 To Len(aTmpSepFp[nL][1])

											If aTmpSepFp[nL][1][nM][nPosTipo] == aTmpCli[nJ][1][nK][nPosTipo] ;
													.And. aTmpSepFp[nL][2] == aTmpCli[nJ][2] ; //lSepFpg
												.And. aTmpSepFp[nL][3] == aTmpCli[nJ][3] ; //lSepMot
												.And. aTmpSepFp[nL][4] == aTmpCli[nJ][4] ; //lSepOrd
												.And. aTmpSepFp[nL][5] == aTmpCli[nJ][5] ; //lRestGrp
												.And. aTmpSepFp[nL][6] == aTmpCli[nJ][6]   //lRestPrd

												lAchou := .T.
												AAdd(aTmpSepFp[nL][1],aTmpCli[nJ][1][nK])
												Exit
											Endif
										Next nM

										If lAchou
											Exit
										Endif
									Next nL

									If !lAchou
										AAdd(aTmpSepFp,{{aTmpCli[nJ][1][nK]},aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
									Endif
								Else
									AAdd(aTmpSepFp,{{aTmpCli[nJ][1][nK]},aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
								Endif
							Next nK
						Else
							AAdd(aTmpSepFp,{aTmpCli[nJ][1],aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
						Endif
					Next nJ

					// Verifica se há separação por motivo de saque
					For nJ := 1 To Len(aTmpSepFp)

						If aTmpSepFp[nJ][3] //.And. !IfVaziaS(aTmpSepFp[nJ][1]) // Separa motivo de saque e possui informação de saque

							For nK := 1 To Len(aTmpSepFp[nJ][1])

								If Len(aTmpSepMt) > 0

									lAchou :=  .F.

									For nL := 1 To Len(aTmpSepMt)

										For nM := 1 To Len(aTmpSepMt[nL][1])

											If aTmpSepMt[nL][1][nM][nPosMotiv] == aTmpSepFp[nJ][1][nK][nPosMotiv] ;
													.And. !Empty(aTmpSepMt[nL][1][nM][nPosMotiv]) ;
													.And. !Empty(aTmpSepFp[nJ][1][nK][nPosMotiv]) ;
													.And. aTmpSepMt[nL][2] == aTmpSepFp[nJ][2] ; //lSepFpg
												.And. aTmpSepMt[nL][3] == aTmpSepFp[nJ][3] ; //lSepMot
												.And. aTmpSepMt[nL][4] == aTmpSepFp[nJ][4] ; //lSepOrd
												.And. aTmpSepMt[nL][5] == aTmpSepFp[nJ][5] ; //lRestGrp
												.And. aTmpSepMt[nL][6] == aTmpSepFp[nJ][6]   //lRestPrd

												lAchou := .T.
												AAdd(aTmpSepMt[nL][1],aTmpSepFp[nJ][1][nK])
												Exit
											Endif
										Next nM

										If lAchou
											Exit
										Endif
									Next nL

									If !lAchou

										AAdd(aTmpSepMt,{{aTmpSepFp[nJ][1][nK]},aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
									Endif
								Else
									AAdd(aTmpSepMt,{{aTmpSepFp[nJ][1][nK]},aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
								Endif
							Next nK
						Else
							AAdd(aTmpSepMt,{aTmpSepFp[nJ][1],aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
						Endif
					Next nJ

					// Verifica se há separação por ordem de serviço
					For nJ := 1 To Len(aTmpSepMt)

						If aTmpSepMt[nJ][4] //.And. !IfVaziaO(aTmpSepMt[nJ][1]) // Separa ordem de serviço e possui ordem de serviço

							For nK := 1 To Len(aTmpSepMt[nJ][1])

								If Len(aTmpSepOs) > 0

									lAchou :=  .F.

									For nL := 1 To Len(aTmpSepOs)

										For nM := 1 To Len(aTmpSepOs[nL][1])

											If aTmpSepOs[nL][1][nM][nPosProdOs] == aTmpSepMt[nJ][1][nK][nPosProdOs] ;
													.And. !Empty(aTmpSepOs[nL][1][nM][nPosProdOs]) ;
													.And. !Empty(aTmpSepMt[nJ][1][nK][nPosProdOs]) ;
													.And. aTmpSepOs[nL][2] == aTmpSepMt[nJ][2] ; //lSepFpg
												.And. aTmpSepOs[nL][3] == aTmpSepMt[nJ][3] ; //lSepMot
												.And. aTmpSepOs[nL][4] == aTmpSepMt[nJ][4] ; //lSepOrd
												.And. aTmpSepOs[nL][5] == aTmpSepMt[nJ][5] ; //lRestGrp
												.And. aTmpSepOs[nL][6] == aTmpSepMt[nJ][6]   //lRestPrd

												lAchou := .T.
												AAdd(aTmpSepOs[nL][1],aTmpSepMt[nJ][1][nK])
												Exit
											Endif
										Next nM

										If lAchou
											Exit
										Endif
									Next nL

									If !lAchou

										AAdd(aTmpSepOs,{{aTmpSepMt[nJ][1][nK]},aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
									Endif
								Else
									AAdd(aTmpSepOs,{{aTmpSepMt[nJ][1][nK]},aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
								Endif
							Next nK
						Else
							AAdd(aTmpSepOs,{aTmpSepMt[nJ][1],aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
						Endif
					Next nJ

					// Verifica se há restrição por Grupo de Produto
					For nJ := 1 To Len(aTmpSepOs)

						If aTmpSepOs[nJ][5] //.And. !RetRpVls(aTmpSepOs[nJ][1]) // Há restrição por Grupo de Produto e não se trata de um agrupamento de requisições ou vale

							For nK := 1 To Len(aTmpSepOs[nJ][1])

								If Len(aTmpGrp) > 0

									cGrpOri := ""

									// Grupo título de origem
									SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
									SD2->(DbGoTop())
									If SD2->(DbSeek(xFilial("SD2", aTmpSepOs[nJ][1][nK][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpSepOs[nJ][1][nK][nPosNumero]+aTmpSepOs[nJ][1][nK][nPosPrefixo]+aTmpSepOs[nJ][1][nK][nPosCliente]+aTmpSepOs[nJ][1][nK][nPosLoja])) //Exclusivo

										SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
										SB1->(DbGoTop())

										If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))

											cGrpOri := SB1->B1_GRUPO
										Endif
									Endif

									lAchou :=  .F.

									For nL := 1 To Len(aTmpGrp)

										For nM := 1 To Len(aTmpGrp[nL][1])

											lAchou :=  .F.
											cGrpDes := ""

											// Grupo título de destino
											SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
											SD2->(DbGoTop())
											If SD2->(DbSeek(xFilial("SD2", aTmpGrp[nL][1][nM][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpGrp[nL][1][nM][nPosNumero]+aTmpGrp[nL][1][nM][nPosPrefixo]+aTmpGrp[nL][1][nM][nPosCliente]+aTmpGrp[nL][1][nM][nPosLoja])) //Exclusivo

												SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
												SB1->(DbGoTop())

												If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))

													cGrpDest := SB1->B1_GRUPO
												Endif
											Endif

											If cGrpOri == cGrpDest ;
													.And. aTmpGrp[nL][2] == aTmpSepOs[nJ][2] ; //lSepFpg
												.And. aTmpGrp[nL][3] == aTmpSepOs[nJ][3] ; //lSepMot
												.And. aTmpGrp[nL][4] == aTmpSepOs[nJ][4] ; //lSepOrd
												.And. aTmpGrp[nL][5] == aTmpSepOs[nJ][5] ; //lRestGrp
												.And. aTmpGrp[nL][6] == aTmpSepOs[nJ][6]   //lRestPrd

												lAchou := .T.
												AAdd(aTmpGrp[nL][1],aTmpSepOs[nJ][1][nK])
												Exit
											Endif
										Next nM

										If lAchou
											Exit
										Endif
									Next nL

									If !lAchou

										AAdd(aTmpGrp,{{aTmpSepOs[nJ][1][nK]},aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
									Endif
								Else
									AAdd(aTmpGrp,{{aTmpSepOs[nJ][1][nK]},aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
								Endif
							Next nK
						Else
							AAdd(aTmpGrp,{aTmpSepOs[nJ][1],aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
						Endif
					Next nJ

					// Verifica se há restrição por Produto
					For nJ := 1 To Len(aTmpGrp)

						If aTmpGrp[nJ][6] //.And. !RetRpVls(aTmpGrp[nJ][1]) // Há restrição por Produto e não se trata de um agrupamento de requisições ou vale

							For nK := 1 To Len(aTmpGrp[nJ][1])

								If Len(aTmpProd) > 0

									cProdOri := ""
									cProdDes := ""

									// Produto título de origem
									SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
									SD2->(DbGoTop())
									If SD2->(DbSeek(xFilial("SD2", aTmpGrp[nJ][1][nK][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpGrp[nJ][1][nK][nPosNumero]+aTmpGrp[nJ][1][nK][nPosPrefixo]+aTmpGrp[nJ][1][nK][nPosCliente]+aTmpGrp[nJ][1][nK][nPosLoja])) //Exclusivo
										cProdOri := SD2->D2_COD
									Endif

									For nL := 1 To Len(aTmpProd)

										For nM := 1 To Len(aTmpProd[nL][1])

											lAchou :=  .F.
											cProdDes := ""

											// Produto título de destino
											SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
											SD2->(DbGoTop())

											If SD2->(DbSeek(xFilial("SD2", aTmpProd[nL][1][nM][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpProd[nL][1][nM][nPosNumero]+aTmpProd[nL][1][nM][nPosPrefixo]+aTmpProd[nL][1][nM][nPosCliente]+aTmpProd[nL][1][nM][nPosLoja])) //Exclusivo
												cProdDest := SD2->D2_COD
											Endif

											If cProdOri == cProdDest ;
													.And. aTmpProd[nL][2] == aTmpGrp[nJ][2] ; //lSepFpg
												.And. aTmpProd[nL][3] == aTmpGrp[nJ][3] ; //lSepMot
												.And. aTmpProd[nL][4] == aTmpGrp[nJ][4] ; //lSepOrd
												.And. aTmpProd[nL][5] == aTmpGrp[nJ][5] ; //lRestGrp
												.And. aTmpProd[nL][6] == aTmpGrp[nJ][6]   //lRestPrd

												lAchou := .T.
												AAdd(aTmpProd[nL][1],aTmpGrp[nJ][1][nK])
												Exit
											Endif
										Next nM

										If lAchou
											Exit
										Endif
									Next nL

									If !lAchou

										AAdd(aTmpProd,{{aTmpGrp[nJ][1][nK]},aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
									Endif
								Else
									AAdd(aTmpProd,{{aTmpGrp[nJ][1][nK]},aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
								Endif
							Next nK
						Else
							AAdd(aTmpProd,{aTmpGrp[nJ][1],aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
						Endif
					Next nJ

					// Faturamento
					// Geração de Faturas
					nAuxFat += Len(aTmpProd)

					For nX := 1 To Len(aTmpProd)

						oSay:cCaption := "Gerando fatura "+cValToChar(nI)+" de "+cValToChar(Len(aCliente))+""
						ProcessMessages()

						aAuxFat := U_TRETE016(aTmpProd[nX][1],aCliente[nI][1],aCliente[nI][2],3,,,,,,,cGet26,,,,,aCpoComp,lFatFat .AND. !lDifCartao)

						If Len(aAuxFat) > 0

							AAdd(aFatura,{aAuxFat[1][1],aAuxFat[1][2],aAuxFat[1][3],aAuxFat[1][4],aAuxFat[1][5],aAuxFat[1][6]})

							if Alltrim(aTmpProd[nX][1][1][nPosTipo]) $ "CC/CD/PX/" //se a fatura é de cartao, chamo baixa
								if MsgYesNo("Fatura "+Alltrim(aTmpProd[nX][1][1][nPosNome])+" gerada! Deseja baixar a fatura?")
									SE1->(DbGoTop())
									SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
									If SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]))
										Liq(SE1->(Recno()), .T.)
									else
										MsgAlert("Falha ao localizar a fatura para baixa!")
									endif
								endif
							elseif lPDFFat
								//Gera arquivo PDF da Fatura
								cBlFuncFat := "U_"+cFImpFat+"(,cFilAnt,{{aAuxFat[1][1],aAuxFat[1][2],aAuxFat[1][3],aAuxFat[1][4],aAuxFat[1][5],aAuxFat[1][6]}},.T.,,,/*@__aArqPDF*/,cGet25)"
								&cBlFuncFat
							endif
						Endif
					Next nX
				Next nI

				// Aviso ao usuário
				If nAuxFat == Len(aFatura)
					MsgInfo("Fatura(s) processada(s) com sucesso.","Atenção")
				ElseIf Len(aFatura) < nAuxFat .And. Len(aFatura) > 0
					MsgInfo("Houve Fatura(s) não processada(s).","Atenção")
				ElseIf Len(aFatura) == 0
					MsgInfo("Nenhuma Fatura gerada.","Atenção")
				Endif

				if lDifCartao
					// Impressão de Faturas
					For nI := 1 To Len(aFatura)

						If nImpFatur == 0

							If MsgYesNo("Deseja imprimir a fatura?")
								
								oSay:cCaption := "Imprimindo fatura "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
								ProcessMessages()

								lImpFatur := .T.
								cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,{{aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]}},.F.,.F.,,,cGet25)"
								&cBlFuncFat
							Endif

							nImpFatur++
						Else
							If lImpFatur
								oSay:cCaption := "Imprimindo fatura "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
								ProcessMessages()

								cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,{{aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]}},.F.,.F.,,,cGet25)"
								&cBlFuncFat
							Endif
						Endif
					Next nI

					// Impressão de Boletos Bancários
					For nI := 1 To Len(aFatura)

						// Verifica se há geração de Boleto Bancário
						// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
						If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+aFatura[nI][2]+aFatura[nI][3]))

							If U88->U88_TPCOBR == "B" // Boleto Bancário

								// Gerar Boleto
								If nGerBol == 0

									If MsgYesNo("Deseja gerar o boleto?")

										oSay:cCaption := "Gerando boleto "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
										ProcessMessages()

										lGerBol := .T.
										FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],"FAT")},'Aguarde','Gerando PDF boleto bancário...')
									Endif

									nGerBol++
								Else
									If lGerBol
										oSay:cCaption := "Gerando boleto "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
										ProcessMessages()

										FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],"FAT")},'Aguarde','Gerando PDF boleto bancário...')
									Endif
								Endif
							Endif
						Else
							// Gerar Boleto
							If nGerBol == 0

								If MsgYesNo("Deseja gerar o boleto?")
									oSay:cCaption := "Gerando boleto "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
									ProcessMessages()

									lGerBol := .T.
									FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],"FAT")},'Aguarde','Gerando PDF boleto bancário...')
								Endif

								nGerBol++
							Else
								If lGerBol
									oSay:cCaption := "Gerando boleto "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
									ProcessMessages()

									FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],"FAT")},'Aguarde','Gerando PDF boleto bancário...')
								Endif
							Endif
						Endif
					Next nI
				Endif

				// Impressão de Boletos Bancários
				If lDifCartao

					If lGerBol // Houve geração de boletos bancários

						DbSelectArea("SE1")

						For nI := 1 To Len(aFatura)

							If nImpBol == 0

								If MsgYesNo("Deseja imprimir o boleto?")

									oSay:cCaption := "Imprimindo boleto "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
									ProcessMessages()

									SE1->(DbGoTop())
									SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

									If SE1->(DbSeek(xFilial("SE1")+aFatura[nI][2]+aFatura[nI][3]+"FAT"+aFatura[nI][1]))

										lImpBol := .T.

										aBoleto := {}

										AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
										AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
										AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
										AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
										AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
										AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - Ate
										AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
										AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
										AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
										AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
										AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
										AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
										AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
										AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
										AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
										AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
										AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
										AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
										AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
										AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
										AAdd(aBoleto,"") 										//Mensagem 1
										AAdd(aBoleto,"") 										//Mensagem 2

										//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
										cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
										FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
									Endif
								Endif

								nImpBol++
							Else
								If lImpBol
									
									oSay:cCaption := "Imprimindo boleto "+cValToChar(nI)+" de "+cValToChar(Len(aFatura))+""
									ProcessMessages()

									SE1->(DbGoTop())
									SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

									If SE1->(DbSeek(xFilial("SE1")+aFatura[nI][2]+aFatura[nI][3]+"FAT"+aFatura[nI][1]))

										lImpBol := .T.

										aBoleto := {}

										AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
										AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
										AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
										AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
										AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
										AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - Ate
										AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
										AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
										AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
										AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
										AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
										AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
										AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
										AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
										AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
										AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
										AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
										AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
										AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
										AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
										AAdd(aBoleto,"") 										//Mensagem 1
										AAdd(aBoleto,"") 										//Mensagem 2

										//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
										cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
										FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
									Endif
								Endif
							Endif
						Next nI
					Endif
				Endif

				// Se houve alteração da database do sistema, retorna a data atual
				If lAltDt
					dDataBase := dDtBkp
				Endif

				If lGeraNF .AND. lDifCartao

					If MsgYesNo("Deseja gerar Nota Fiscal das faturas geradas?")
						oSay:cCaption := "Abrindo monitor de notas fiscais..."
						ProcessMessages()
						MonitorNotas(aFatura)
					endif

					/*For nI := 1 To Len(aFatura)

						// Gerar N. Fiscal
						If nGeraNfe == 0

							If MsgYesNo("Deseja gerar Nota Fiscal?")

								// vejo se utilizo a filial de origem
								If lMVVFilOri 

									// posiciono no registro da SE1
									SE1->(DbGoTop())
									SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
									SE1->(DbSeek(xFilial("SE1")+aFatura[nI][2]+aFatura[nI][3]+"FAT"+aFatura[nI][1]))

									// pego a filial de origem
									cFilFatura := SE1->E1_FILORIG
									
								Else
									cFilFatura	:= cFilAnt
								EndIf

								lGeraNfe := .T.

								FWMsgRun(,{|oSay| lOkNfe := U_TRETE019(cFilFatura,;
									aFatura[nI][4],;
									aFatura[nI][1],;
									aFatura[nI][5],;
									aFatura[nI][6],;
									aFatura[nI][2],;
									aFatura[nI][3],;
									,;
									.F.)},'Aguarde','Gerando Nota Fiscal...')
								If lOkNfe
									nAuxNfe++
								Endif
							Endif

							nGeraNfe++
						Else
							If lGeraNfe

								// vejo se utilizo a filial de origem
								If lMVVFilOri

									// posiciono no registro da SE1
									SE1->(DbGoTop())
									SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
									SE1->(DbSeek(xFilial("SE1")+aFatura[nI][2]+aFatura[nI][3]+"FAT"+aFatura[nI][1]))

									// pego a filial de origem
									cFilFatura := SE1->E1_FILORIG
									
								Else
									cFilFatura	:= cFilAnt
								EndIf

								FWMsgRun(,{|oSay| lOkNfe := U_TRETE019(cFilFatura,;
									aFatura[nI][4],;
									aFatura[nI][1],;
									aFatura[nI][5],;
									aFatura[nI][6],;
									aFatura[nI][2],;
									aFatura[nI][3],;
									,;
									.F.)},'Aguarde','Gerando Nota Fiscal...')

								If lOkNfe
									nAuxNfe++
								Endif
							Endif
						Endif
					Next nI*/

				Endif

				// Aviso ao usuário
				/*If lGeraNfe .AND. lDifCartao
					If nAuxNfe == 0
						MsgInfo("Nenhuma Nota Fiscal gerada.","Atenção")
					ElseIf Len(aFatura) > nAuxNfe .And. Len(aFatura) > 0
						MsgInfo("Houve Nota(s) Fiscal(is) não processada(s).","Atenção")
					ElseIf nAuxNfe == Len(aFatura)
						MsgInfo("Processamento finalizado.","Atenção")
					Endif
				Endif*/

				// Envio de e-mail com anexos do faturamento
				If lDifCartao //Len(aFatura) == 1 
					// Envio de e-mail com anexos do faturamento
					If lEnvArqs
						If MsgYesNo("Deseja enviar e-mail do faturamento?")
							oSay:cCaption := "Carregando dados para envio de e-mail..."
							ProcessMessages()

							//ordeno o array de faturas por cliente
							ASort(aFatura,,,{|x,y| x[2] + x[3] + x[1] < y[2] + y[3] + y[1] })

							cCli			:= aFatura[1][2]
							cLojaCli		:= aFatura[1][3]
							aAuxFat 		:= {}
							nQtdFat			:= Len(aFatura)

							For nI := 1 To nQtdFat
								aadd(aAuxFat, {aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]} )

								if nI+1 <= nQtdFat
									cCli			:= aFatura[nI+1][2]
									cLojaCli		:= aFatura[nI+1][3]
								endif

								if cCli+cLojaCli <> aFatura[nI][2]+aFatura[nI][3] .OR. nI == nQtdFat
									U_TRETE044(cFilAnt, aAuxFat )					
									aAuxFat := {}
								endif
							Next nI
						Endif
					Endif

				Endif

			Else // Fatura de Fatura

				oSay:cCaption := "Gerando fatura 1 de 1"
				ProcessMessages()

				aFatura := U_TRETE016(aTit,cCli,cLojaCli,4,,,,,,,cGet26)

				If Len(aFatura) > 0

					//Gera arquivo PDF da Fatura
					if lPDFFat
						cBlFuncFat := "U_"+cFImpFat+"(,cFilAnt,{{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}},.T.,,,/*@__aArqPDF*/,cGet25)"
						&cBlFuncFat
					endif

					If nImpFatur == 0
						If MsgYesNo("Deseja imprimir a fatura?")
							lImpFatur := .T.
							cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,{{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}},.F.,.F.,,,cGet25)"
							&cBlFuncFat
						Endif

						nImpFatur++
					Else
						If lImpFatur
							cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,{{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}},.F.,.F.,,,cGet25)"
							&cBlFuncFat
						Endif
					Endif

					// Verifica se há geração de Boleto Bancário
					// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
					If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+aFatura[1][2]+aFatura[1][3]))

						If U88->U88_TPCOBR == "B" // Boleto Bancário

							// Gerar Boleto
							If nImpBol == 0

								If MsgYesNo("Deseja gerar o boleto?")

									lImpBol := .T.
									FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[1][1],aFatura[1][2],aFatura[1][3],"FAT")},'Aguarde','Imprimindo boleto bancário...')
								Endif

								nImpBol++
							Else
								If lImpBol
									FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[1][1],aFatura[1][2],aFatura[1][3],"FAT")},'Aguarde','Imprimindo boleto bancário...')
								Endif
							Endif
						Endif
					Endif

					// Impressão de Boletos Bancários
					If lGerBol // Houve geração de boletos bancários

						DbSelectArea("SE1")

						If nImpBol == 0

							If MsgYesNo("Deseja imprimir o boleto?")

								SE1->(DbGoTop())
								SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

								If SE1->(DbSeek(xFilial("SE1")+aFatura[1][2]+aFatura[1][3]+"FAT"+aFatura[1][1]))

									lImpBol := .T.

									aBoleto := {}

									AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
									AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
									AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
									AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
									AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
									AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - Ate
									AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
									AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
									AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
									AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
									AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
									AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
									AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
									AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
									AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
									AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
									AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
									AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
									AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
									AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
									AAdd(aBoleto,"") 										//Mensagem 1
									AAdd(aBoleto,"") 										//Mensagem 2

									//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
									cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
									FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
								Endif
							Endif

							nImpBol++
						Else
							If lImpBol

								SE1->(DbGoTop())
								SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

								If SE1->(DbSeek(xFilial("SE1")+aFatura[1][2]+aFatura[1][3]+"FAT"+aFatura[1][1]))

									lImpBol := .T.

									aBoleto := {}

									AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
									AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
									AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
									AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
									AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
									AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - Ate
									AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
									AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
									AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
									AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
									AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
									AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
									AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
									AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
									AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
									AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
									AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
									AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
									AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
									AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
									AAdd(aBoleto,"") 										//Mensagem 1
									AAdd(aBoleto,"") 										//Mensagem 2

									//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
									cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
									FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
								Endif
							Endif
						Endif
					Endif

					// Envio de e-mail com anexos do faturamento
					If lEnvArqs
						If MsgYesNo("Deseja enviar e-mail do faturamento?")
							U_TRETE044(cFilAnt, {{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}})
						Endif
					Endif

				Endif

			Endif

			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
		Endif
	Endif

// Se houve alteração da database do sistema, retorna a data atual
	If lAltDt
		dDataBase := dDtBkp
	Endif

Return

/****************************/
Static Function FatFlex(oSay)
/****************************/

	Local aTit			:= {}
	Local aFatura 		:= {}

	Local lFatFat		:= .F.
	Local lCliDif		:= .F.
	Local cCli			:= ""
	Local cLojaCli		:= ""

	Local nI

	Local lOkNfe
	Local lGeraNFe		:= .F.
	Local nAuxNfe		:= 0

	Local lAltDt		:= .F.
	Local dDtBkp		:= CToD("")

	Local lHasCartao	:= .F.
	Local lDifCartao	:= .F.
	Local cBandSAE		:= ""
	Local lBandDif		:= .F.
	Local cOperSAE		:= ""
	Local lOperDif		:= .F.
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cFilFatura	:= ""
	Local cBlFuncBol
	Local cBlFuncFat

	Private lFluxoFAT	:= .T. //Variavel para indicar que está no fluxo de faturamento (usada no boleto Decio)

	If dGet24 <> dDataBase //Dt. referência diferente da Data atual
		dDtBkp		:= dDataBase
		dDataBase 	:= dGet24
		lAltDt 		:= .T.
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T. // Título selecionado

			If Val(StrTran(StrTran(cValToChar(aReg[nI][nPosSaldo]),".",""),",",".")) == 0 // Título baixado

				MsgInfo("O Título ["+AllTrim(aReg[nI][nPosNumero])+"] não se encontra em aberto, operação não permitida.","Atenção")

				If lAltDt
					dDataBase := dDtBkp
				Endif

				Return
			Endif

			//verificando se tem titulo de cartao selecionado
			If AllTrim(aReg[nI][nPosTipo]) $ "CC/CD/CCP/CDP/PX/" 
				lHasCartao	:= .T.
			endif

			//Verificando diferenca de bandeira/operadora, em caso de faturar cartoes ou fatura de cartao
			//TODO Ajustar posicionamento para buscar do campo E1_ADM
			If Empty(cBandSAE)
				cBandSAE := Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_ADMCART")
			Else
				If cBandSAE <> Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_ADMCART")
					lBandDif := .T.
				Endif
			Endif
			If Empty(cOperSAE)
				cOperSAE := Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_REDEAUT")
			Else
				If cOperSAE <> Posicione("SAE",1,xFilial("SAE")+Alltrim(aReg[nI][nPosCliente]),"AE_REDEAUT")
					lOperDif := .T.
				Endif
			Endif

			//verificando se é faturamento de outra fatua, e se é fatura que não é de catao
			If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
				//If !AllTrim(aReg[nI][nPosOriFat]) $ "CC/FT/CD/FT/CDP/FT/CCP/FT"
				If !("CC" $ aReg[nI][nPosOriFat] .OR. "CD" $ aReg[nI][nPosOriFat] .OR. "PX" $ aReg[nI][nPosOriFat])
					lDifCartao := .T.
				Endif

				lFatFat := .T.
			else
				If !("CC" $ AllTrim(aReg[nI][nPosTipo]) .OR. "CD" $ AllTrim(aReg[nI][nPosTipo]) .OR. "PX" $ AllTrim(aReg[nI][nPosTipo]))
					lDifCartao := .T.
				Endif
			Endif

			//Verifica se tem cliente diferente
			If Empty(cCli)
				cCli		:= aReg[nI][nPosCliente]
				cLojaCli 	:= aReg[nI][nPosLoja]
			Else
				If cCli <> aReg[nI][nPosCliente] .Or. cLojaCli <> aReg[nI][nPosLoja]
					lCliDif := .T.
				Endif
			Endif

			AAdd(aTit,aReg[nI])
		Endif
	Next

	If lFatFat .And. (lBandDif .Or. lOperDif) .And. !lDifCartao

		MsgInfo("Em caso de Faturamento de Cartão/Pix, os títulos obrigatoriamente devem possuir a mesma Bandeira e Operadora.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return

	ElseIf lFatFat .And. lCliDif .And. lDifCartao

		MsgInfo("Em caso de Faturamento de Faturas, os títulos obrigatoriamente devem pertencer a um mesmo Cliente e Loja.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return

	ElseIf !lFatFat .And. lHasCartao .AND. (lBandDif .Or. lOperDif) 

		MsgInfo("Em caso de Faturamento de Cartão, os títulos obrigatoriamente devem possuir a mesma Bandeira e Operadora.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return

	ElseIf !lFatFat .And. lCliDif .AND. !lHasCartao //nao tem cartao e cliente diferente, bloqueia

		MsgInfo("Em caso de Faturamento, os títulos obrigatoriamente devem pertencer a um mesmo Cliente e Loja.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

	If PesqBol()

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

	If Len(aTit) > 0

		If MsgYesNo("Haverá o faturamento dos registros selecionados, deseja continuar?")

			oSay:cCaption := "Gerando fatura..."
			ProcessMessages()

			aFatura := U_TRETE016(aTit,cCli,cLojaCli,3,,lFatFat,.T.,,,,cGet26,,,,,,lFatFat .AND. !lDifCartao)

			// Aviso ao usuário
			If Len(aFatura) > 0

				if lHasCartao
					if MsgYesNo("Fatura "+Alltrim(aTit[1][nPosNome])+" gerada!"+CRLF+CRLF+"Número da Fatura: " + aFatura[1][1] +CRLF+CRLF+ "Deseja baixar a fatura?")
						SE1->(DbGoTop())
						SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						If SE1->(DbSeek(xFilial("SE1")+aFatura[1][2]+aFatura[1][3]+"FAT"+aFatura[1][1]))
							Liq(SE1->(Recno()), .T.)
						else
							MsgAlert("Falha ao localizar a fatura para baixa!")
						endif
					endif
				else
					//Gera arquivo PDF da Fatura
					if lPDFFat
						cBlFuncFat := "U_"+cFImpFat+"(,cFilAnt,{{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}},.T.,,,/*@__aArqPDF*/,cGet25)"
						&cBlFuncFat
					endif
					
					MsgInfo("Fatura processada com sucesso."+CRLF+CRLF+"Número da Fatura: " + aFatura[1][1],"Atenção")

				endif
			Else
				MsgInfo("Nenhuma Fatura gerada.","Atenção")
			Endif

			If Len(aFatura) > 0
				if !lHasCartao
					If MsgYesNo("Deseja imprimir a fatura?")
						cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,{{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}},.F.,.F.,,,cGet25)"
						&cBlFuncFat
					Endif

					// Verifica se há geração de Boleto Bancário
					// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
					If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+aFatura[1][2]+aFatura[1][3]))

						If U88->U88_TPCOBR == "B" // Boleto Bancário
							// Gerar Boleto
							If MsgYesNo("Deseja gerar o boleto?")
								FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[1][1],aFatura[1][2],aFatura[1][3],"FAT")},'Aguarde','Imprimindo boleto bancário...')

								If MsgYesNo("Deseja imprimir o boleto?")
									SE1->(DbGoTop())
									SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
									If SE1->(DbSeek(xFilial("SE1")+aFatura[1][2]+aFatura[1][3]+"FAT"+aFatura[1][1]))

										aBoleto := {}

										AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
										AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
										AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
										AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
										AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
										AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - Ate
										AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
										AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
										AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
										AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
										AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
										AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
										AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
										AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
										AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
										AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
										AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
										AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
										AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
										AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
										AAdd(aBoleto,"") 										//Mensagem 1
										AAdd(aBoleto,"") 										//Mensagem 2

										//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
										cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
										FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
									Endif
								
								Endif
							Endif
						Endif
					else
						// Gerar Boleto
						If MsgYesNo("Deseja gerar o boleto?")
							FWMsgRun(,{|oSay| ImpBol(oSay,4,cFilAnt,aFatura[1][1],aFatura[1][2],aFatura[1][3],"FAT")},'Aguarde','Imprimindo boleto bancário...')

							If MsgYesNo("Deseja imprimir o boleto?")
								SE1->(DbGoTop())
								SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
								If SE1->(DbSeek(xFilial("SE1")+aFatura[1][2]+aFatura[1][3]+"FAT"+aFatura[1][1]))

									aBoleto := {}

									AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
									AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
									AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
									AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
									AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
									AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - Ate
									AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
									AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
									AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
									AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
									AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
									AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
									AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
									AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
									AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
									AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
									AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
									AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
									AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
									AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
									AAdd(aBoleto,"") 										//Mensagem 1
									AAdd(aBoleto,"") 										//Mensagem 2

									//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
									cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
									FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
								Endif
							
							Endif
						Endif
					Endif

					If MsgYesNo("Deseja gerar Nota Fiscal das faturas geradas?")
						MonitorNotas(aFatura)
					endif
					
					/*If MsgYesNo("Deseja gerar Nota Fiscal?")

						// vejo se utilizo a filial de origem
						If lMVVFilOri

							// posiciono no registro da SE1
							SE1->(DbGoTop())
							SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
							SE1->(DbSeek(xFilial("SE1")+aFatura[1][2]+aFatura[1][3]+"FAT"+aFatura[1][1]))

							// pego a filial de origem
							cFilFatura := SE1->E1_FILORIG
							
						Else
							cFilFatura	:= cFilAnt
						EndIf

						FWMsgRun(,{|oSay| lOkNfe := U_TRETE019(cFilFatura,;
							aFatura[1][4],;
							aFatura[1][1],;
							aFatura[1][5],;
							aFatura[1][6],;
							aFatura[1][2],;
							aFatura[1][3],;
							,;
							.F.)},'Aguarde','Gerando Nota Fiscal...')

						If lOkNfe
							nAuxNfe++
						Endif

						lGeraNfe := .T.
					Endif

					// Aviso ao usuário
					If lGeraNfe
						If nAuxNfe == 0
							MsgInfo("Nenhuma Nota Fiscal gerada.","Atenção")
						Else
							MsgInfo("Processamento finalizado.","Atenção")
						Endif
					Endif*/

					// Envio de e-mail com anexos do faturamento
					If MsgYesNo("Deseja enviar e-mail do faturamento?")
						U_TRETE044(cFilAnt, {{aFatura[1][1],aFatura[1][2],aFatura[1][3],aFatura[1][4],aFatura[1][5],aFatura[1][6]}})
					Endif
					
				endif
				Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
			Endif
		Endif
	Else
		MsgInfo("Nenhum registro selecionado.","Atenção")
	Endif

// Se houve alteração da database do sistema, retorna a data atual
	If lAltDt
		dDataBase := dDtBkp
	Endif

Return

/***************************/
Static Function CanFat(oSay)
/***************************/

	Local nI, nX
	Local lContinua	:= .T.
	Local aTitCanc	:= {}
	Local cQry		:= ""
	Local aTitFt	:= {}
	Local nIncLog	:= 0
	Local aDadosLog	:= {}
	Local aDadosFat	:= {}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		Return
	Endif

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T.
			If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
				DbSelectArea("SE1")
				SE1->(DbGoto(aReg[nI][nPosRecno]))
				If !ValidFin()
					lContinua := .F.
					Exit //sai do For nI
				Elseif "PARCE. " $ SE1->E1_HIST //verifico se o titulo FT é originado da rotina Parcelar
					MsgInfo("O título ["+AllTrim(aReg[nI][nPosNumero])+"] selecionado é uma fatura de origem da opção Parcelar. Utilize opção Est. Parcelamento.","Atenção")
					lContinua := .F.
					Exit //sai do For nI
				Else
					AAdd(aTitCanc,{aReg[nI][nPosFatura],aReg[nI][nPosRecno]})
				EndIf
			Else
				MsgInfo("O título ["+AllTrim(aReg[nI][nPosNumero])+"] selecionado não se trata de uma fatura, operação não permitida.","Atenção")
				lContinua := .F.
				Exit //sai do For nI
			Endif
		Endif
	Next

	If lContinua

		If Len(aTitCanc) > 0

			For nI := 1 To Len(aTitCanc)

				oSay:cCaption := "Cancelando fatura "+cValToChar(nI)+" de "+cValToChar(Len(aTitCanc))+""
				ProcessMessages()

				DbSelectArea("SE1")
				SE1->(DbGoto(aTitCanc[nI][2]))
				
				aDadosFat := {}
				AAdd(aDadosFat,{SE1->E1_PREFIXO,;
								SE1->E1_NUM,;
								SE1->E1_PARCELA,;
								SE1->E1_TIPO})

				// Exclui borderô
				ExcBord(aTitCanc[nI][2])

				// Verifica versão da fatura
				If !Empty(SE1->E1_NUMLIQ) // Liquidação
					aTitFt := U_TRETE016(,,,5,aTitCanc[nI][1])
					lContinua := aTitFt[1] //se retornou .T., é pq deu certo o estorno
				Else // Fatura

					If Select("QRYFAT") > 0
						QRYFAT->(dbCloseArea())
					Endif

					cQry := "SELECT SE1.R_E_C_N_O_ AS SE1RECNO"
					cQry += " FROM "+RetSqlName("SE1")+" SE1"
					cQry += " WHERE SE1.D_E_L_E_T_	<> '*'"
					cQry += " AND SE1.E1_FILIAL		= '"+SE1->E1_FILIAL+"'"
					cQry += " AND SE1.E1_FATURA		= '"+SE1->E1_NUM+"'"
					cQry += " AND SE1.E1_TIPO		= 'FT '" //Fatura

					cQry := ChangeQuery(cQry)
					//MemoWrite("c:\temp\RFATE001CANFAT.txt",cQry)
					TcQuery cQry NEW Alias "QRYFAT"

					While QRYFAT->(!EOF())
						AAdd(aTitFt,QRYFAT->SE1RECNO)
						QRYFAT->(DbSkip())
					EndDo

					If Select("QRYFAT") > 0
						QRYFAT->(dbCloseArea())
					Endif

					//compatibilidade com a função padrão FINA280
					mv_par01	:= 2 //Contabiliza OnLine? - Nao
					mv_par02	:= 2 //Mostra Lanc Contab? - Nao
					mv_par05 	:= 1 //Excluir cheques? - Sim
					lF280Auto	:= .F.
					lSE1Compart	:= .F.
					LOPCAUTO	:= .F.
					FA280CAN("SE1",'41', 3, .F.,.T.)

					//Ajusta os títulos "filhos" do tipo fatura
					DbSelectArea("SE1")

					For nX := 1 To Len(aTitFt)

						SE1->(DbGoto(aTitFt[nX]))

						RecLock("SE1",.F.)
						SE1->E1_FATURA 	:= "NOTFAT"
						SE1->(MsUnlock())
					Next nX
				EndIf
				
				// Verifica se o Log de Exclusão consta ativado
				If lLogExc
					If nIncLog == 0
						aDadosLog := U_TRETE040(1,aDadosFat)
						nIncLog++
					Else
						U_TRETE040(1,aDadosFat,aDadosLog,.T.)//automatico
					EndIf
				EndIf
			Next nI

			if lContinua
				MsgInfo("Processamento finalizado.","Atenção")
			endif
			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
		Else
			MsgInfo("Nenhum registro selecionado.","Atenção")
		Endif
	Endif

Return

/***************************/
Static Function DetFat(oSay)
/***************************/

	Local nI
	Local nCont 	:= 0

	Local cCli		:= ""
	Local cLojaCli	:= ""
	Local cTit		:= ""
	Local cPref		:= ""
	Local cParc		:= ""
	Local cTp		:= ""

	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cFilFatura 	:= ""

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.

			cCli 		:= aReg[nI][nPosCliente]	// Cliente
			cLojaCli	:= aReg[nI][nPosLoja]		// Loja
			cPref		:= aReg[nI][nPosPrefixo]	// Prefixo
			cTit		:= aReg[nI][nPosNumero]		// Número liquidação
			cParc		:= aReg[nI][nPosParcela]	// Parcela
			cTp			:= aReg[nI][nPosTipo]		// Tipo

			// vejo se utilizo a filial de origem
			If lMVVFilOri 
				// pego a filial de origem
				cFilFatura := aReg[nI][nPosFilOri]
			Else
				cFilFatura	:= aReg[nI][nPosFilial]
			EndIf

			If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
				lFatura		:= .T.
			Else
				lFatura		:= .F.
			Endif

			nCont++
		Endif
	Next

	If nCont > 1

		MsgInfo("O detalhamento é executado para um título de cada vez.","Atenção")

	ElseIf nCont == 1

		oSay:cCaption := "Detalhando fatura..."
		ProcessMessages()

		U_TRETE018(cFilFatura,cCli,cLojaCli,cPref,cTit,cParc,cTp,lFatura)
	Else
		MsgInfo("Nenhum registro selecionado.","Atenção")
	Endif

Return

/*********************************/
Static Function ImpFat(oSay,_nOpc)
/*********************************/

	Local nI
	Local nCont 	:= 0
	Local cBlFuncFat
	Local aFat		:= {}

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.

			nCont++

			If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
				//Número 				Cliente 				Loja			 Prefixo				 Parcela 				Tipo
				AAdd(aFat,{aReg[nI][nPosNumero],aReg[nI][nPosCliente],aReg[nI][nPosLoja],aReg[nI][nPosPrefixo],aReg[nI][nPosParcela],aReg[nI][nPosTipo]})
			Else
				MsgInfo("Dentre o(s) registro(s) selecionado(s), o título ["+AllTrim(aReg[nI][nPosNumero])+"] não se trata de uma fatura, sendo assim, não será impresso.","Atenção")
			Endif
		Endif
	Next

	If nCont > 0 .And. Len(aFat) > 0

		If _nOpc == 1 // Direto na porta
			cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,aFat,.F.,.T.,,,cGet25)"
			&cBlFuncFat
			MsgInfo("Processamento finalizado.","Atenção")
		Elseif _nOpc == 2 //em tela
			cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,aFat,,,,,cGet25)"
			&cBlFuncFat
		elseif _nOpc == 3 //excel
			U_TRETE048(oSay, cFilAnt,aFat,cGet25)
		Endif

	ElseIf nCont > 0 .And. Len(aFat) == 0
		MsgInfo("Nenhum título do tipo fatura selecionado.","Atenção")
	Else
		MsgInfo("Nenhum registro selecionado.","Atenção")
	Endif

Return

/*****************************************************************/
Static Function ImpBol(oSay,nTp,_cFilial,_cFatura,_cCli,_cLojaCli, _cPrefix, _cParcel)
/*****************************************************************/

	Local nI
	Local nCont		:= 0
	Local aBoleto 	:= {}

	Local cQry		:= ""

	Local aImp		:= {}

	Local lAltDt	:= .F.
	Local dDtBkp	:= CToD("")

	Local lImprime	:= .T.

	Local cBlFuncBol

	If dGet24 <> dDataBase // Dt. referência diferente da Data atual
		dDtBkp		:= dDataBase
		dDataBase 	:= dGet24
		lAltDt 		:= .T.
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Endif

	DbSelectArea("U88")
	U88->(DbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA

	If nTp == 1 .Or. nTp == 2 .Or. nTp == 3 //Gerar/Imprimir direto na porta Ou Gerar/Imprimir em tela

		For nI := 1 To Len(aReg)

			If aReg[nI][nPosMark] == .T.

				lImprime := .T.

				// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
				If U88->(DbSeek(xFilial("U88")+aReg[nI][nPosTipo]+Space(6 - Len(aReg[nI][nPosTipo]))+aReg[nI][nPosCliente]+aReg[nI][nPosLoja])) //Compartilhado

					If U88->U88_BOLCOR == "S" // Imprime Boleto
						lImprime := .T.
					Else
						lImprime := .F.
					Endif
				Endif

				nCont++

				aBoleto := {}

				AAdd(aBoleto,aReg[nI][nPosPrefixo]) 					//Prefixo - De
				AAdd(aBoleto,aReg[nI][nPosPrefixo]) 					//Prefixo - Ate
				AAdd(aBoleto,aReg[nI][nPosNumero]) 						//Numero - De
				AAdd(aBoleto,aReg[nI][nPosNumero]) 						//Numero - Ate
				AAdd(aBoleto,aReg[nI][nPosParcela]) 					//Parcela - De
				AAdd(aBoleto,aReg[nI][nPosParcela]) 					//Parcela - Ate
				AAdd(aBoleto,aReg[nI][nPosDeposit]) 					//Portador - De
				AAdd(aBoleto,aReg[nI][nPosDeposit]) 					//Portador - Ate
				AAdd(aBoleto,aReg[nI][nPosCliente]) 					//Cliente - De
				AAdd(aBoleto,aReg[nI][nPosCliente]) 					//Cliente - Ate
				AAdd(aBoleto,aReg[nI][nPosLoja]) 						//Loja - De
				AAdd(aBoleto,aReg[nI][nPosLoja]) 						//Loja - Ate
				AAdd(aBoleto,CToD(aReg[nI][nPosEmissao])) 				//Emissão - De
				AAdd(aBoleto,CToD(aReg[nI][nPosEmissao])) 				//Emissão - Ate
				AAdd(aBoleto,DataValida(CToD(aReg[nI][nPosVencto])))	//Vencimento - De
				AAdd(aBoleto,DataValida(CToD(aReg[nI][nPosVencto])))	//Vencimento - Ate
				AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
				AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
				AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
				AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
				AAdd(aBoleto,"") 										//Mensagem 1
				AAdd(aBoleto,"") 										//Mensagem 2

				If nTp == 1 .Or. nTp == 2 // Gerar/Imprimir direto na porta
					aImp := GetImpWindows(.F.) // Busca a relacao de impressoras da estacao, onde a primeira da lista e a padrao
					//U_TRETR009(aBoleto,aImp[1],,,lImprime)
					cBlFuncBol := "U_"+cFImpBol+"(aBoleto,aImp[1],,,lImprime)"
					&cBlFuncBol
				Else // Gerar/Imprimir em tela
					//U_TRETR009(aBoleto,,,,.F.)
					cBlFuncBol := "U_"+cFImpBol+"(aBoleto,,,,.F.)"
					&cBlFuncBol
				Endif
			Endif
		Next

		If nCont == 0
			MsgInfo("Nenhum registro selecionado.","Atenção")
		Else
			If nTp == 1
				MsgInfo("Processamento finalizado.","Atenção")
			Endif

			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
		Endif

	Else // Função Faturar

		If Select("QRYFAT") > 0
			QRYFAT->(dbCloseArea())
		Endif

		cQry := "SELECT E1_PREFIXO, E1_NUM, E1_PARCELA, E1_PORTADO, E1_EMISSAO, E1_VENCTO"
		cQry += CRLF + " FROM "+RetSqlName("SE1")+""
		cQry += CRLF + " WHERE D_E_L_E_T_	<> '*'"
		cQry += CRLF + " AND E1_FILIAL		= '"+xFilial("SE1",_cFilial)+"'"
		cQry += CRLF + " AND E1_NUM			= '"+_cFatura+"'"
		cQry += CRLF + " AND E1_CLIENTE		= '"+_cCli+"'"
		cQry += CRLF + " AND E1_LOJA		= '"+_cLojaCli+"'"
		if _cPrefix <> Nil
			cQry += " AND E1_PREFIXO 	= '"+_cPrefix+"'"
		endif
		if _cParcel <> Nil
			cQry += " AND E1_PARCELA	= '"+_cParcel+"'"
		endif

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETE017.txt",cQry)
		TcQuery cQry NEW Alias "QRYFAT"

		AAdd(aBoleto,QRYFAT->E1_PREFIXO) 						//Prefixo - De
		AAdd(aBoleto,QRYFAT->E1_PREFIXO) 						//Prefixo - Ate
		AAdd(aBoleto,QRYFAT->E1_NUM)	 						//Numero - De
		AAdd(aBoleto,QRYFAT->E1_NUM)	 						//Numero - Ate
		AAdd(aBoleto,QRYFAT->E1_PARCELA) 						//Parcela - De
		AAdd(aBoleto,QRYFAT->E1_PARCELA) 						//Parcela - Ate
		AAdd(aBoleto,QRYFAT->E1_PORTADO) 						//Portador - De
		AAdd(aBoleto,QRYFAT->E1_PORTADO) 						//Portador - Ate
		AAdd(aBoleto,_cCli)				 						//Cliente - De
		AAdd(aBoleto,_cCli)				 						//Cliente - Ate
		AAdd(aBoleto,_cLojaCli)			 						//Loja - De
		AAdd(aBoleto,_cLojaCli)			 						//Loja - Ate
		AAdd(aBoleto,SToD(QRYFAT->E1_EMISSAO))					//Emissão - De
		AAdd(aBoleto,SToD(QRYFAT->E1_EMISSAO))					//Eemissão- Ate
		AAdd(aBoleto,DataValida(SToD(QRYFAT->E1_VENCTO)))		//Vencimento - De
		AAdd(aBoleto,DataValida(SToD(QRYFAT->E1_VENCTO)))		//Vencimento - Ate
		AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
		AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
		AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
		AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
		AAdd(aBoleto,"") 										//Mensagem 1
		AAdd(aBoleto,"") 										//Mensagem 2

		QRYFAT->(dbCloseArea())

		//U_TRETR009(aBoleto,,,.T.,.F.)
		cBlFuncBol := "U_"+cFImpBol+"(aBoleto,,,.T.,.F.)"
		&cBlFuncBol
	Endif

	// Se houve alteração da database do sistema, retorna a data atual
	If lAltDt
		dDataBase := dDtBkp
	Endif

Return

/******************************/
Static Function TransMBol(oSay)
/******************************/

	Local nI
	Local nCont		:= 0
	Local lAux 		:= .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		Return
	Endif

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	If lAux

		If MsgYesNo("Haverá a transferência de Borderô para Carteira o títulos selecionados, deseja continuar?")

			For nI := 1 To Len(aReg)

				If aReg[nI][nPosMark] == .T.

					oSay:cCaption := "Transferindo "+cValToChar(nI)+" de "+cValToChar(Len(aReg))+""
					ProcessMessages()

					// Se houver borderô associado, exclui
					DbSelectArea("SE1")
					SE1->(DbGoTo(aReg[nI][nPosRecno]))

					DbSelectArea("SEA")
					SEA->(DbSetOrder(1)) // EA_FILIAL+EA_NUMBOR+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA

					If SEA->(DbSeek(xFilial("SEA")+SE1->E1_NUMBOR+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))

						RecLock("SEA")
						SEA->(DbDelete())
						SEA->(MsUnlock())

						SE1->(DbGoTo(aReg[nI][nPosRecno]))
						RecLock("SE1")
						SE1->E1_SITUACA	:= "0"
						SE1->E1_OCORREN	:= ""
						SE1->E1_NUMBOR	:= ""
						SE1->E1_DATABOR	:= CToD("")
						SE1->(MsUnLock())
					Endif
				Endif
			Next nI

			MsgInfo("Processamento finalizado.","Atenção")
			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
		Endif
	Endif

Return

/******************************/
Static Function Liq(_nRecnoSE1, lAfterFT)
/******************************/

	Local nI
	Local nCont		:= 0
	Local lAux 		:= .T.
	Local nSaldo	:= 0

	Local lRet		:= .T.

	Local cBkpFunNam := FunName()

	Default lAfterFT := .F.

	ALTERA := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		Return
	Endif
	if lAfterFT
		DbSelectArea("SE1")
		SE1->(DbGoto(_nRecnoSE1))
		nSaldo := SE1->E1_SALDO
		nCont++
	else
		For nI := 1 To Len(aReg)
			If aReg[nI][nPosMark] == .T.
				nSaldo := Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",",".")) //Saldo
				nCont++
			Endif
		Next
	endif

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	ElseIf nCont > 1
		MsgInfo("A liquidação deve ser realizada para um título de cada vez.","Atenção")
		lAux := .F.
	Endif

	If lAux
		If nSaldo > 0

			If _nRecnoSE1 <> 0
				If !lAfterFT .AND. !MsgYesNo("Haverá a liquidação do registro selecionado, deseja continuar?")
					Return
				Else
					DbSelectArea("SE1")
					SE1->(DbGoto(_nRecnoSE1))

					SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)
					lRet := FINA070(,3,.T.) // Função padrão
					SetFunName(cBkpFunNam)

					If lRet .AND. !lAfterFT
						Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
					Endif
				Endif
			Else
				MsgInfo("Registro não localizado.","Atenção")
			Endif
		Else
			MsgInfo("Título já liquidado, operação não permitida.","Atenção")
		Endif
	Endif

Return

/************************/
Static Function GeraNFe()
/************************/

	Local aArea			:= GetArea()
	Local aAreaSE1		:= SE1->(GetArea())
	Local cFilFatura	:= ""
	Local lAux 			:= .T.
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local nAuxNfe		:= 0
	Local nI			:= 0
	Local nCont			:= 0

	Local lOk		:= .T.

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	If lAux

		If MsgYesNo("Haverá a geração de N. Fiscal para os registros selecionados, deseja continuar?")

			For nI := 1 To Len(aReg)

				If aReg[nI][nPosMark] == .T.

					If !U_TR042VCN(AllTrim(aReg[nI][nPosCliente]), AllTrim(aReg[nI][nPosLoja]))
						MsgInfo("Cliente de destino ["+AllTrim(aReg[nI][nPosCliente])+"], referente a Venda ["+AllTrim(aReg[nI][nPosNumero])+"], não pode ser igual a um Cliente padrão.","Atenção")
					Else

						// vejo se utilizo a filial de origem
						If lMVVFilOri .And. aReg[nI][nPosRecno] > 0 

							// posiciono no registro da SE1
							SE1->(DbGoTo(aReg[nI][nPosRecno]))

							// pego a filial de origem
							cFilFatura := SE1->E1_FILORIG
							
						Else
							cFilFatura	:= cFilAnt
						EndIf

						FWMsgRun(,{|oSay| lOk := U_TRETE019(cFilFatura,;
							aReg[nI][nPosPrefixo],;
							aReg[nI][nPosNumero],;
							aReg[nI][nPosParcela],;
							aReg[nI][nPosTipo],;
							aReg[nI][nPosCliente],;
							aReg[nI][nPosLoja],;
							,;
							.F.)},'Aguarde','Gerando Nota Fiscal...')

						If lOk
							nAuxNfe++
						Endif
					Endif
				Endif
			Next nI

			// Aviso ao usuário
			If nAuxNfe == 0
				MsgInfo("Nenhuma Nota Fiscal gerada.","Atenção")
			ElseIf nAuxNfe < nCont
				MsgInfo("Houve Nota(s) Fiscal(is) não processada(s).","Atenção")
			ElseIf nAuxNfe == nCont
				MsgInfo("Processamento finalizado.","Atenção")
			Endif

			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
		Endif
	Endif

	RestArea(aAreaSE1)
	RestArea(aArea)

Return(Nil)

/***********************/
Static Function EstNFe()
/***********************/

	Local aArea 	:= GetArea()
	Local aAreaSF2	:= SF2->(GetArea())
	Local aAreaSD2	:= SD2->(GetArea())
	Local aAreaMDL	:= MDL->(GetArea())
	Local aAreaSF3	:= SF3->(GetArea())
	Local aAreaSFT	:= SFT->(GetArea())

	Local aSay := {}
	Local aBut := {}
	Local lOk		:= .F.

	//texto da tela
	aAdd(aSay, "Esta rotina tem por estornar NF-e geradas no conceito Notas Sobre Cupom/NFCe.")
	aAdd(aSay, "Observe que somente serão consideradas notas que estejam dentro do prazo")
	aAdd(aSay, "de cancelamento da sefaz, definido no parametro MV_SPEDEXC.")
	aAdd(aSay, "")
	aAdd(aSay, "Ao confirmar esta tela, utilize os filtros da tela a seguir para localizar ")
	aAdd(aSay, "a(s) nota(s) a estornar.")

	//botoes da tela
	aAdd(aBut, {01, .T., {|| FechaBatch(), lOk := .T., U_TRETE033() } })	// Confirma
	aAdd(aBut, {02, .T., {|| lOk := .F., FechaBatch() } })	// Cancela

	//abre tela
	FormBatch("Estorno de NF sobre Cupom.", aSay, aBut)

	if lOk
		Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
	endif

	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
	RestArea(aAreaMDL)
	RestArea(aAreaSF3)
	RestArea(aAreaSFT)
	RestArea(aArea)

Return

/***********************/
Static Function ImpNFe()
/***********************/

	Local nI
	Local nCont			:= 0
	Local lAux 			:= .T.

	Local oSay1, oSay2
	Local oButton1, oButton2

	Local oQtdVia

	Private _nQtdVia	:= 1

	Static oDlgImpNfe

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	If lAux

		DEFINE MSDIALOG oDlgImpNfe TITLE "Quantidade de vias" From 000,000 TO 120,212 PIXEL

		@ 010, 010 SAY oSay1 PROMPT "Qtde. Vias" SIZE 080, 007 OF oDlgImpNfe COLORS 0, 16777215 PIXEL
		@ 010, 055 MSGET oQtdVia VAR _nQtdVia SIZE 030, 010 OF oDlgImpNfe COLORS 0, 16777215 Valid(ValQtdVia(_nQtdVia)) PIXEL Picture "@E 9"

		// Linha horizontal
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
		MsgInfo("A Quantidade de vias não pode ser inferior a 1 (uma) via.","Atenção")
		lRet := .F.
	Endif

Return lRet

/***************************/
Static Function ConfImpNfe()
/***************************/

	Local nI, nJ

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.

			For nJ := 1 To _nQtdVia
				//Filial			Tipo				Número				Cliente					Loja
				U_TRETE037(aReg[nI][iif(nPosFilOri>0,nPosFilOri,nPosFilial)],aReg[nI][nPosTipo],aReg[nI][nPosNumero],aReg[nI][nPosCliente],aReg[nI][nPosLoja])
			Next nJ
		Endif
	Next nI

	oDlgImpNfe:End()

	MsgInfo("Processamento finalizado.","Atenção")

	Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")

Return

//chama tela de NF-s Sefaz conforme escolha da filial
Static Function CallNfeSefaz(cFilNfe)

	Local lFinded := .F.
	Local aArea := GetArea()
	Local aAreaSM0 := SM0->( GetArea() )
	Local cBkpFilAnt := cFilAnt

	if cFilNfe == Nil 
		SPEDNFE()
	else
		//forço o posicionamento na SM0
		SM0->(DbGoTop())
		While SM0->(!Eof())
			If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilNfe)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
				lFinded := .T.
				cFilAnt := cFilNfe
				Exit
			EndIf
			SM0->(DbSkip())
		EndDo
		if lFinded
			SPEDNFE()
		endif
	endif

	cFilAnt := cBkpFilAnt
	RestArea(aAreaSM0)
	RestArea(aArea)

Return

/*************************************/
Static Function OrderGrid(oObj,nColum)
/*************************************/

	If nColum <> 1 .And. nColum <> 2 .And. nColum <> nPosRecno // Flag seleção e Legenda e RECNO

		If !lFatConv // Diferente de conveniência

			// Valor ou Saldo ou Desconto ou Multa ou Juros ou Acréscimo ou Decréscimo - N
			If nColum == nPosValor .Or. nColum == nPosSaldo .Or. nColum == nPosDescont .Or. nColum == nPosMulta .Or. nColum == nPosJuros .Or. nColum == nPosAcresc .Or. nColum == nPosDecres .OR. nColum == nPosVlAcess

				ASort(aReg,,,{|x,y| (StrZero(INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")))) * 1000) + x[nPosNumero] ) < ( StrZero(INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")))) * 1000) + y[nPosNumero])})

				// Tipo ou Descrição ou Prefixo ou Número ou Parcela ou Natureza ou Portador ou Depositaria ou Nro. da Conta ou Nome Banco ou Placa ou Cliente
				// ou Loja ou Nome ou Classe ou Cond. pagto. - C
			ElseIf nColum == nPosTipo .Or. nColum == nPosDescri .Or. nColum == nPosPrefixo .Or. nColum == nPosNumero .Or. nColum == nPosParcela .Or. nColum == nPosNaturez .Or. nColum == nPosPortado .Or. nColum == nPosDeposit .Or.;
					nColum == nPosNConta .Or. nColum == nPosBanco .Or. nColum == nPosPlaca .Or. nColum == nPosCliente .Or. nColum == nPosLoja .Or. nColum == nPosNome .Or. nColum == nPosClasse .Or. nColum == nPosCondPg

				ASort(aReg,,,{|x,y| x[nColum] + x[nPosNumero] < y[nColum] + y[nPosNumero]})

				// Dt. Emissão ou Dt. Vencimento
			ElseIf nColum == nPosEmissao .Or. nColum == nPosVencto

				ASort(aReg,,,{|x,y| DToS(CToD(x[nColum])) + x[nPosNumero] < DToS(CToD(y[nColum])) + y[nPosNumero]})
			Endif

			oBrw:SetArray(aReg)
			oBrw:bLine := bBrwLine
			oBrw:Refresh()
		Else
			// Valor ou Saldo ou Desconto ou Multa ou Juros ou Acréscimo ou Decréscimo - N
			If nColum == nPosValor .Or. nColum == nPosSaldo .Or. nColum == nPosDescont .Or. nColum == nPosMulta .Or. nColum == nPosJuros .Or. nColum == nPosAcresc .Or. nColum == nPosDecres .Or. nColum == nPosVlAcess

				ASort(aReg,,,{|x,y| (StrZero(INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(x[nColum]),".",""),",",".")))) * 1000) + x[nPosNumero] ) < ( StrZero(INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",","."))),10) + cValToChar((Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")) - INT(Val(StrTran(StrTran(cValToChar(y[nColum]),".",""),",",".")))) * 1000) + y[nPosNumero])})

				// Tipo ou Descrição ou Prefixo ou Número ou Parcela ou Natureza ou Portador ou Depositaria ou Nro. da Conta ou Nome Banco ou Placa ou Cliente
				// ou Loja ou Nome ou Classe ou Cond. pagto. - C
			ElseIf nColum == nPosTipo .Or. nColum == nPosDescri .Or. nColum == nPosPrefixo .Or. nColum == nPosNumero .Or. nColum == nPosParcela .Or. nColum == nPosNaturez .Or. nColum == nPosPortado .Or. nColum == nPosDeposit .Or.;
					nColum == nPosNConta .Or. nColum == nPosBanco .Or. nColum == nPosCliente .Or. nColum == nPosLoja .Or. nColum == nPosNome .Or. nColum == nPosCondPg

				ASort(aReg,,,{|x,y| x[nColum] + x[nPosNumero] < y[nColum] + y[nPosNumero]})

				// Dt. Emissão ou Dt. Vencimento
			ElseIf nColum == nPosEmissao .Or. nColum == nPosVencto

				ASort(aReg,,,{|x,y| DToS(CToD(x[nColum])) + x[nPosNumero] < DToS(CToD(y[nColum])) + y[nPosNumero]})
			Endif

			oBrw:SetArray(aReg)
			oBrw:bLine := bBrwLine
			oBrw:Refresh()
		EndIf
	Endif

Return

/***********************/
Static Function SelBco()
/***********************/

	Local nI
	Local nAux			:= 0

	Local oButton1, oButton2

	Private oSay1, oSay2, oSay3, oSay4

	Private oBco
	Private oAgencia
	Private oConta
	Private cBco 		:= Space(TamSX3("E1_PORTADO")[1])
	Private cAgencia	:= Space(TamSX3("E1_AGEDEP")[1])
	Private cConta		:= Space(TamSX3("E1_CONTA")[1])

	Private oNomeBco
	Private cNomeBco	:= ""

	Static oDlgBco

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		Return
	Endif

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T.
			nAux++
		Endif
	Next

	If nAux == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		Return
	Endif

	DEFINE MSDIALOG oDlgBco TITLE "Selecionar Banco Cobrança" From 000,000 TO 115,400 PIXEL

	@ 005, 005 SAY oSay1 PROMPT "Portador:" SIZE 040, 007 OF oDlgBco COLORS CLR_BLUE, 16777215 PIXEL
	@ 005, 040 MSGET oBco VAR cBco SIZE 020, 010 OF oDlgBco COLORS 0, 16777215 HASBUTTON PIXEL Valid IIF(!Empty(cBco),ValBco(),.T.) F3 "SA6" Picture "@!"
	@ 005, 080 SAY oNomeBco PROMPT cNomeBco SIZE 120, 007 OF oDlgBco COLORS 0, 16777215 PIXEL
	@ 018, 005 SAY oSay2 PROMPT "Agência:" SIZE 040, 007 OF oDlgBco COLORS 0, 16777215 PIXEL
	@ 018, 040 MSGET oAgencia VAR cAgencia SIZE 030, 010 OF oDlgBco COLORS 0, 16777215 PIXEL WHEN .F.
	@ 018, 080 SAY oSay3 PROMPT "Conta:" SIZE 040, 007 OF oDlgBco COLORS 0, 16777215 PIXEL
	@ 018, 115 MSGET oConta VAR cConta SIZE 060, 010 OF oDlgBco COLORS 0, 16777215 PIXEL WHEN .F.

// Linha horizontal
	@ 030, 005 SAY oSay4 PROMPT Repl("_",190) SIZE 190, 007 OF oDlgBco COLORS CLR_GRAY, 16777215 PIXEL

	@ 041, 110 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgBco ACTION ConfSel() PIXEL
	@ 041, 155 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgBco ACTION oDlgBco:End() PIXEL

	ACTIVATE MSDIALOG oDlgBco CENTERED

Return

/***********************/
Static Function ValBco()
/***********************/

	Local lRet := .T.

	dbSelectArea("SA6")
	SA6->(dbSetOrder(1)) // A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON

	If !Empty(cBco)

		If !SA6->(DbSeek(xFilial("SA6")+cBco+cAgencia+cConta))

			MsgInfo("Banco inválido.","Atenção")

			cNomeBco 	:= ""
			cAgencia	:= ""
			cConta		:= ""

			lRet 		:= .F.
		Else
			cNomeBco	:= SA6->A6_NOME
		Endif
	Else
		cNomeBco 	:= ""
		cAgencia	:= ""
		cConta		:= ""
	Endif

	oNomeBco:Refresh()

Return lRet

/************************/
Static Function ConfSel()
/************************/

	Local nI
	Local cDirDes  	:= "system\"+SuperGetMv("MV_XDIRBMO",.F.,"arquivos_mo\boletos\") //destino dos arquivos (arquivos_mo\boletos\)
	Local cFilePrint
	Local cMask := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"

	If !Empty(cBco)

		dbSelectArea("SE1")

		For nI := 1 To Len(aReg)

			If aReg[nI][nPosMark] == .T.

				If !Empty(SE1->E1_NUMBOR)

					// Exclui título do borderô
					ExcBord(aReg[nI][nPosRecno])
				EndIf

				SE1->(DbGoTo(aReg[nI][nPosRecno])) //R_E_C_N_O_

				RecLock("SE1",.F.)
				SE1->E1_PORTADO := cBco
				SE1->E1_AGEDEP	:= cAgencia
				SE1->E1_CONTA	:= cConta
				SE1->E1_NUMBCO  := ""
				SE1->E1_OCORREN  := ""
				SE1->E1_CODBAR  := ""
				SE1->E1_CODDIG  := ""
				SE1->E1_XDVNNUM := ""
				SE1->(MsUnlock())
				
				cFilePrint	:= "BOLETO_" + Alltrim(SE1->E1_FILIAL) + "_" + AllTrim(SE1->E1_NUM) + "_" + AllTrim(SE1->E1_CLIENTE) + AllTrim(SE1->E1_LOJA) + "_" +;
					Upper(AllTrim(SE1->E1_NOMCLI)) + "_" + SubStr(DToS(dDataBase),7,2) + SubStr(DToS(dDataBase),5,2) + SubStr(DToS(dDataBase),1,4)
				
				//trato nome arquivo 
				cFilePrint := StrTran(cFilePrint," ","_")
				cFilePrint := U_MYNOCHAR(cFilePrint, cMask)

				if !File(cDirDes + cFilePrint + ".pdf")
					If FErase(cDirDes + cFilePrint + ".pdf") == 0
						//conout(" >> Excluido arquivo <"+ "system\" + cDirDes + cFilePrint + ".pdf" +">")
					EndIf
				endif
			Endif
		Next

		MsgInfo("Alteração realizada com sucesso.","Atenção")
		oDlgBco:End()
		Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
	Else
		MsgInfo("Campo <Portador> obrigatório.","Atenção")
	Endif

Return

/**********************/
Static Function Reneg()
/**********************/

	Local nI
	Local nCont		:= 0
	Local nSaldo	:= 0

	Local lAux 		:= .T.

	Local nRecSE1	:= 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento não é menor que data limite de ³
//³ movimentacao no financeiro									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !DtMovFin()
		Return
	Endif

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T.
			nCont++
		EndIf
	Next nI

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		lAux := .F.
	Endif

	If lAux

		For nI := 1 To Len(aReg)

			If aReg[nI][nPosMark] == .T.

				nSaldo 	:= Val(StrTran(StrTran(aReg[nI][nPosSaldo],".",""),",",".")) //Saldo
				nRecSE1	:= aReg[nI][nPosRecno] //R_E_C_N_O_

				If nSaldo > 0

					_nOpc := SelOpc()

					If _nOpc ==  1 .Or. _nOpc == 2 .Or. _nOpc == 3 .Or. _nOpc == 4

						If _nOpc == 1 // Alterar Data de Vencimento

							AltDtVenc(nRecSE1,aReg[nI])

						ElseIf _nOpc == 2 // Reparcelar

							Parcelar(nRecSE1,aReg[nI])

						ElseIf _nOpc == 3 // Reparcelar (flexível)

							ParcFlex(nRecSE1,aReg[nI])

						Else // Imprimir Contrato de Renegociação
							if ExistBlock("TR017CRN") //PE para impressão do contra de renegociação
        						ExecBlock("TR017CRN",.F.,.F.,aReg)
							else
								//U_TRETR012(aReg)
							endif
						Endif
					Else // Cancelou
						Return
					Endif
				Else
					MsgInfo("Título já liquidado, operação não permitida.","Atenção")
					lAux := .F.
				Endif
			EndIf
		Next nI

		Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
	Endif

Return

//Incluido por André R. Barrero - 11/08/2015
/*******************************/
Static Function EstRen(oSay,lFatParc)
/*******************************/

Local nI, nJ
Local nCont		:= 0
Local nSaldo	:= 0
Local lAux 		:= .T.
Local nRecSE1	:= 0

Local cQry		:= ""

Local cCliente	:= ""
Local cLoja		:= ""
Local cPrefixo	:= ""
Local cNum		:= ""
Local cParcela	:= ""
Local cTipo		:= ""
Local cHist		:= ""

Local aNumPai	:= {}
Local aTitRen	:= {}

Local lCancela 	:= .F.
Local nQualBaixa := 0

Local aDadosFat	:= {}

Default lFatParc 	:=	.F.

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Exclui o título selecionado e cancela a baixa do título 	 ³
//³ de onde se originou											 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !DtMovFin()
	Return
Endif

For nI := 1 To Len(aReg)

	If aReg[nI][nPosMark] == .T.
		nSaldo 	:= Val(StrTran(StrTran(aReg[nI][nPosSaldo],".",""),",",".")) //Saldo
		nRecSE1	:= aReg[nI][nPosRecno] //R_E_C_N_O_
		nCont++
	Endif
Next

If nCont == 0
	MsgInfo("Nenhum registro selecionado!!","Atenção")
	lAux := .F.
Endif

If nCont > 1
	MsgInfo("O estorno da renegociação deve ser realizado para um título de cada vez!!","Atenção")
	lAux := .F.
Endif

If lAux

	If nSaldo > 0

		DbSelectArea("SE1")
		SE1->(DbGoTo(nRecSE1))

		If !ValidFin()
			Return
		EndIf

		if !lFatParc .AND. SE1->E1_PREFIXO <> "REN"
			Alert("Titulo não é de renegociação! Ação não permitida.")
			Return
		endif

		// Verifica versão da fatura
		If !lFatParc .AND. !Empty(SE1->E1_NUMLIQ) // Liquidação

			If MsgYesNo("Deseja executar o estorno do Título:'"+AllTrim(SE1->E1_NUM)+"' Parcela:'"+AllTrim(SE1->E1_PARCELA)+"' Tipo:'"+AllTrim(SE1->E1_TIPO)+;
					"' Prefixo:'"+AllTrim(SE1->E1_PREFIXO)+"' ?","Atenção")

				aDadosFat := {}

				//pego chave do titulo de origem
				FI7->(DbSetOrder(2))//FI7_FILIAL+FI7_PRFDES+FI7_NUMDES+FI7_PARDES+FI7_TIPDES+FI7_CLIDES+FI7_LOJDES
				FI7->(DbSeek(xFilial("FI7")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) ))
				While FI7->(!Eof()) .AND. FI7->(FI7_FILIAL+FI7_PRFDES+FI7_NUMDES+FI7_PARDES+FI7_TIPDES) == xFilial("FI7")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)
					if FI7->FI7_TIPORI <> "NCC"
						cPrefixo := FI7->FI7_PRFORI
						cNum := FI7->FI7_NUMORI
						cParcela := FI7->FI7_PARORI
						cTipo := FI7->FI7_TIPORI
						cCliente := FI7->FI7_CLIORI
						cLoja := FI7->FI7_LOJORI
						EXIT
					endif
					FI7->(DbSkip())
				enddo

				//verifico se algum dos titulos da mesma liquidação está baixado
				If Select("QRYSE1") > 0
					QRYSE1->(DbCloseArea())
				EndIf

				cQry := " SELECT SE1.R_E_C_N_O_ RECSE1 "
				cQry += " FROM "+RetSqlName("SE1")+" SE1  "
				cQry += " INNER JOIN "+RetSqlName("FI7")+" FI7_1 "
				cQry += " 	ON FI7_1.FI7_PRFDES	= SE1.E1_PREFIXO "
				cQry += " 	AND FI7_1.FI7_NUMDES	= SE1.E1_NUM "
				cQry += " 	AND FI7_1.FI7_PARDES	= SE1.E1_PARCELA "
				cQry += " 	AND FI7_1.FI7_TIPDES	= SE1.E1_TIPO "
				cQry += " 	AND FI7_1.FI7_CLIDES	= SE1.E1_CLIENTE "
				cQry += " 	AND FI7_1.FI7_LOJDES	= SE1.E1_LOJA "
				cQry += " 	AND FI7_1.D_E_L_E_T_	<> '*' "
				cQry += " 	AND FI7_1.FI7_FILIAL	= '"+xFilial("FI7")+"' "
				cQry += " WHERE  "
				cQry += " SE1.D_E_L_E_T_	<> '*' "
				cQry += " AND SE1.E1_FILIAL	= '"+xFilial("SE1")+"' "
				cQry += " AND (FI7_1.FI7_PRFORI + FI7_1.FI7_NUMORI + FI7_1.FI7_PARORI + FI7_1.FI7_TIPORI + FI7_1.FI7_CLIORI + FI7_1.FI7_LOJORI) IN ( "
				cQry += " 	SELECT "
				cQry += " 	(FI7_2.FI7_PRFORI + FI7_2.FI7_NUMORI + FI7_2.FI7_PARORI + FI7_2.FI7_TIPORI + FI7_2.FI7_CLIORI + FI7_2.FI7_LOJORI) "
				cQry += " 	FROM "+RetSqlName("FI7")+" FI7_2 "
				cQry += " 	WHERE  "
				cQry += " 	FI7_2.FI7_PRFDES	= '"+SE1->E1_PREFIXO+"' "
				cQry += " 		AND FI7_2.FI7_NUMDES	= '"+SE1->E1_NUM+"' "
				cQry += " 		AND FI7_2.FI7_PARDES	= '"+SE1->E1_PARCELA+"' "
				cQry += " 		AND FI7_2.FI7_TIPDES	= '"+SE1->E1_TIPO+"' "
				cQry += " 		AND FI7_2.FI7_CLIDES	= '"+SE1->E1_CLIENTE+"' "
				cQry += " 		AND FI7_2.FI7_LOJDES	= '"+SE1->E1_LOJA+"' "
				cQry += " 		AND FI7_2.D_E_L_E_T_	<> '*' "
				cQry += " 		AND FI7_2.FI7_FILIAL	= '"+xFilial("FI7")+"' "
				cQry += " ) "

				cQry := ChangeQuery(cQry)
				//MemoWrite("c:\temp\RFATE001_32.txt",cQry)
				TcQuery cQry New Alias "QRYSE1"

				If QRYSE1->(!Eof())

					// inicio o controle de transação para estorno de título
					BeginTran()

					While QRYSE1->(!EOF())

						SE1->(DbGoTo(QRYSE1->RECSE1))

						AAdd(aDadosFat,{SE1->E1_PREFIXO,;
								SE1->E1_NUM,;
								SE1->E1_PARCELA,;
								SE1->E1_TIPO})

						if SE1->E1_VALLIQ > 0
							MsgInfo("Título pertencente a fatura já liquidado ou baixado, operação não permitida!";
								+CRLF+"Título:'"+AllTrim(SE1->E1_NUM)+"' Parcela:'"+AllTrim(SE1->E1_PARCELA)+"' Tipo:'"+AllTrim(SE1->E1_TIPO)+"' Prefixo:'"+AllTrim(SE1->E1_PREFIXO)+"'";
								,"Atenção")
							lAux := .F.
							EXIT
						endif

						If !ValidFin()
							lAux := .F.
							EXIT
						EndIf

						If !Empty(SE1->E1_NUMBOR)
							//Exclui título do borderô
							ExcBord(QRYSE1->RECSE1)
						EndIf

						QRYSE1->(DbSkip())
					EndDo

					if lAux
						
						SE1->(DbGoTo(nRecSE1))
						aTitRen := U_TRETE016(,,,5,SE1->E1_NUMLIQ) 

						if aTitRen[1] //se retornou .T., é que deu certo o cancelamento
						
							SE1->(DbSetOrder(1))
							SE1->(DbSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+cTipo))
							AjustaValor(0, 0)

							// Verifica se o Log de Exclusão consta ativado
							If lLogExc
								U_TRETE040(2,aDadosFat)
							EndIf

							MsgInfo("Processo de estorno finalizado!","Atenção")

						endif
						
					else
						DisarmTransaction()
					endif

					EndTran()

				else
					Alert("Referencia ao título pai não existe!")
					Return
				EndIf
				
			EndIf

		else

			If Select("QRYSE1") > 0
				QRYSE1->(DbCloseArea())
			EndIf

			//verifica se tem titulos filho
			cQry := " SELECT SE1.E1_NUM"
			cQry += " FROM "+RetSqlName("SE1")+" SE1"
			cQry += " WHERE D_E_L_E_T_		<> '*'"
			cQry += " AND SE1.E1_FILIAL   	= '"+xFilial("SE1")+"'"
			cQry += " AND SE1.E1_CLIENTE   	= '"+SE1->E1_CLIENTE+"'"
			cQry += " AND SE1.E1_LOJA   	= '"+SE1->E1_LOJA+"'"
			cQry += " AND SE1.E1_HIST	    LIKE '%"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+"%'"

			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\RFATE001_32.txt",cQry)
			TcQuery cQry New Alias "QRYSE1"

			If QRYSE1->(!Eof())

				Alert("Não é possível estornar título que contenha um Título (filho) derivado de renegociação!!")

				Return
			EndIf

			QRYSE1->(DbCloseArea())

			If MsgYesNo("Deseja executar o estorno do Título:'"+AllTrim(SE1->E1_NUM)+"' Parcela:'"+AllTrim(SE1->E1_PARCELA)+"' Tipo:'"+AllTrim(SE1->E1_TIPO)+"' Prefixo:'"+AllTrim(SE1->E1_PREFIXO)+"' ?","Atenção")

				cCliente	:= SE1->E1_CLIENTE
				cLoja		:= SE1->E1_LOJA
				If !lFatParc
					cTipo		:= SE1->E1_TIPO
				EndIf
				cHist		:= SE1->E1_HIST

				If !Empty(cHist)

					If Select("QRYREN") > 0
						QRYREN->(DbCloseArea())
					EndIf

					//Procura pelo Título Pai
					cQry := " SELECT R_E_C_N_O_ AS RECTIT"
					cQry += " FROM "+RetSqlName("SE1")+" "
					cQry += " WHERE D_E_L_E_T_ 	<> '*' "
					cQry += " AND E1_HIST    	= '"+cHist+"' "

					cQry := ChangeQuery(cQry)
					//MemoWrite("c:\temp\RFATE001_42.txt",cQry)
					TcQuery cQry New Alias "QRYREN"

					While QRYREN->(!EOF())

						Aadd(aTitRen,QRYREN->RECTIT)

						QRYREN->(DbSkip())
					EndDo

					If At("-",cHist) > 0 //RENEG. FAT-000002054/101
						aNumPai := StrToKArr(AllTrim(SubStr(cHist,8,Len(cHist)-8)), "/")
						cPrefixo:= SubStr(aNumPai[1],1,3)
						cNum	:= PadL(SubStr(aNumPai[1],5,9),tamsx3("E1_NUM")[1],"0")
						cParcela:= PadR(aNumPai[2],tamsx3("E1_PARCELA")[1]," ")
					Else //RENEG. TIT 000002054/102
						aNumPai := StrToKArr(AllTrim(SubStr(cHist,12,Len(cHist)-12)), "/")
						cPrefixo:= ""
						cNum	:= PadL(aNumPai[1],tamsx3("E1_NUM")[1],"0")
						cParcela:= PadR(aNumPai[2],tamsx3("E1_PARCELA")[1]," ")

						If Select("QRYSE1") > 0
							QRYSE1->(DbCloseArea())
						EndIf

						//Procura pelo Título Pai
						cQry := " SELECT E1_PREFIXO"
						cQry += " FROM "+RetSqlName("SE1")+" "
						cQry += " WHERE D_E_L_E_T_ <> '*' "
						cQry += " AND E1_FILIAL   	= '"+xFilial("SE1")+"' "
						cQry += " AND E1_CLIENTE   	= '"+cCliente+"' "
						cQry += " AND E1_LOJA   	= '"+cLoja+"' "
						cQry += " AND E1_NUM     	= '"+cNum+"' "
						cQry += " AND E1_PARCELA    = '"+cParcela+"' "
						If !lFatParc
							cQry += " AND E1_TIPO    	= '"+cTipo+"' "
						EndIf

						cQry := ChangeQuery(cQry)
						//MemoWrite("c:\temp\RFATE001_52.txt",cQry)
						TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

						If QRYSE1->(!Eof())
							cPrefixo:= QRYSE1->E1_PREFIXO
						EndIf

						If Select("QRYSE1")>0
							QRYSE1->(DbCloseArea())
						EndIf
					EndIf

				Else
					Alert("Referencia ao título pai não existe!")
					Return
				EndIf

				//Posiciona no Título Pai
				SE1->( DbSetOrder(2) ) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				If SE1->( DbSeek(xFilial("SE1")+cCliente+cLoja+cPrefixo+cNum+cParcela+cTipo) )

					//If !ValidFin() --> não precisa validar título pai
					//	Return
					//EndIf

					//Cancela a baixa do Título Pai
					aFin070 := {}
					Aadd( aFin070, {"E1_FILIAL"  , xFilial("SE1")	, Nil})
					Aadd( aFin070, {"E1_PREFIXO" , cPrefixo			, Nil})
					Aadd( aFin070, {"E1_NUM"     , cNum		   		, Nil})
					Aadd( aFin070, {"E1_PARCELA" , cParcela 		, Nil})
					If !lFatParc
						Aadd( aFin070, {"E1_TIPO"    , cTipo	   		, Nil})
					Else
						Aadd( aFin070, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})
					EndIf

					//tratamento para pegar apenas a ultima baixa, nos casos de o titulo pai tiver outas baixas parciais.
					aBaixaSE5 := {} //private para funçao padrao add os dados
					//Sel070Baixa - retorna os registros das baixas realizadas do título a ser cancelado
					Sel070Baixa( "VL /V2 /BA /RA /CP /LJ /"+MV_CRNEG,SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA,SE1->E1_TIPO,,,SE1->E1_CLIENTE,SE1->E1_LOJA,0/*@nSaldo*/,,,,.T.)
					//aBaixaSE5 := aSort(aBaixaSE5,,, { |x,y| x[9] > y[9] } ) // Ordeno pela sequencia de baixa desc
					//nQualBaixa := Val(aBaixaSE5[1][9]) // sequencia da ultima baixa
					nQualBaixa := len(aBaixaSE5) //ultima baixa

				Else
					MsgInfo("Não foi localizado o Título Pai:'"+cNum+"' Parcela:'"+cParcela+"' Tipo:'"+cTipo+"' Prefixo:'"+cPrefixo+"' !","Atenção")
					Return
				EndIf

				// inicio o controle de transação para estorno de título
				BeginTran()

				For nJ := 1 To Len(aTitRen)

					lMsErroAuto := .F.

					SE1->(DbSelectArea("SE1"))
					SE1->(DbGoTo(aTitRen[nJ]))

					If !ValidFin()
						DisarmTransaction()
						lCancela := .T.
						Exit //sai do Next nJ
					EndIf

					If !Empty(SE1->E1_NUMBOR)
						//Exclui título do borderô
						ExcBord(aTitRen[nJ])
					EndIf

					aFin040 := {}

					Aadd( aFin040, {"E1_FILIAL"  , xFilial("SE1")	, Nil})
					Aadd( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
					Aadd( aFin040, {"E1_NUM"     , SE1->E1_NUM		, Nil})
					Aadd( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA	, Nil})
					Aadd( aFin040, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verifica se o titulo esta em TELECOBRANCA                   ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					SK1->(DbSelectarea("SK1"))
					SK1->(DbSetorder(1))             // K1_FILIAL+K1_PREFIXO+K1_NUM+K1_PARCELA+K1_TIPO
					If SK1->( DbSeek( xFilial("SK1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO) )
						If SK1->K1_OPERAD != "XXXXXX"
							If MsgYesNo("Este título encontra em cobrança, deseja excluir assim mesmo?")
								RecLock("SK1", .F.)
								SK1->(DbDelete())
								SK1->(MsUnlock())
							Else
								DisarmTransaction()
								lCancela := .T.
								Exit //sai do For nJ
							EndIf
						EndIf
					EndIf

					//Exclui Títulos renegociados
					MsExecAuto( { |x,y| Fina040(x,y)} , aFin040, 5)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
					If lMsErroAuto
						MostraErro()
						DisarmTransaction()
						lCancela := .T.
						Exit //sai do For nJ
					Else
						//MsgInfo("Exclusão do Título:'"+aReg[nI][7]+"' Parcela:'"+aReg[nI][8]+"' Tipo:'"+aReg[nI][4]+"' Prefixo:'"+aReg[nI][6]+"' executada com sucesso!")
					EndIf

				Next nJ

				If !lCancela
					//Cancela baixa do Título Pai
					MSExecAuto({|x,w,y,z| Fina070(x,w,y,z)}, aFin070, 6,, iif(nQualBaixa > 1, nQualBaixa, Nil)) //rotina automática para cancelamento da baixa;

					If lMsErroAuto
						MostraErro()
						DisarmTransaction()
					Else
						MsgInfo("Processo de estorno finalizado!","Atenção")
					EndIf
				Else
					MsgInfo("Não foi feito o Estorno do Título selecionado!","Atenção")
				EndIf

				EndTran()

			Else //Deseja executar o estorno do Título - Não

				Return
			endif

		EndIf

	Else
		MsgInfo("Título já liquidado ou baixado, operação não permitida!","Atenção")
		lAux := .F.
	Endif
Endif

Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")

Return

//--------------------------------------------------------------
// Realiza o Faturamento individual
//--------------------------------------------------------------
Static Function FatInd(oSay)

	Local aTit			:= {}
	Local aAuxFat		:= {}
	Local aFatura 		:= {}
	Local aBoleto 		:= {}

	Local lFatFat		:= .F.
	Local cCli			:= ""
	Local cLojaCli		:= ""
	Local cNumFat		:= ""

	Local lGerBol
	Local cChvTit		:= ""
	Local lFatParc		:= .F.
	Local nI, nQtdFat

	Local lAltDt		:= .F.
	Local dDtBkp		:= CToD("")

	Private lFluxoFAT	:= .T. //Variavel para indicar que está no fluxo de faturamento (usada no boleto Decio)

	If dGet24 <> dDataBase //Dt. referência diferente da Data atual
		dDtBkp		:= dDataBase
		dDataBase 	:= dGet24
		lAltDt 		:= .T.
	Endif

	//Verifica se data do movimento não é menor que data limite de
	//movimentacao no financeiro									
	If !DtMovFin()
		If lAltDt
			dDataBase := dDtBkp
		Endif
		Return
	Endif

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T. //Título selecionado

			If Val(StrTran(StrTran(cValToChar(aReg[nI][nPosSaldo]),".",""),",",".")) == 0 //Título baixado
				MsgInfo("O Título <"+AllTrim(aReg[nI][nPosNumero])+"> não se encontra em aberto, operação não permitida.","Atenção")

				If lAltDt
					dDataBase := dDtBkp
				Endif

				Return
			Endif

			if !lFatParc .AND. aScan(aTit, {|x| x[nPosPrefixo]+x[nPosNumero] == aReg[nI][nPosPrefixo]+aReg[nI][nPosNumero] } ) > 0
				lFatParc := .T.
			endif

			AAdd(aTit,aReg[nI])

		Endif
	Next nI

	If PesqBol()
		If lAltDt
			dDataBase := dDtBkp
		Endif
		Return
	Endif

	If Len(aTit) > 0

		If MsgYesNo("Haverá o faturamento individual dos registros selecionados, deseja continuar?")
			
			if lFatParc
				//ordeno o array de titulos para faturamento
				ASort(aTit,,,{|x,y| x[nPosPrefixo] + x[nPosNumero] + x[nPosParcela] < y[nPosPrefixo] + y[nPosNumero] + y[nPosParcela] })
			endif

			For nI := 1 To Len(aTit)

				oSay:cCaption := "Gerando fatura..." + cValToChar(nI) + " de " + cValToChar(len(aTit))
				ProcessMessages()

				lFatFat := .F.

				If AllTrim(aTit[nI][nPosTipo]) == "FT"
					lFatFat := .T.
				Endif

				cCli		:= aTit[nI][nPosCliente]
				cLojaCli 	:= aTit[nI][nPosLoja]

				//logica para manter numero da fatura e apenas sequenciar parcela
				cNumFat	:= "" 
				if lFatParc
					//verifico se é a mesma chave do titulo anterior, 
					if cChvTit == aTit[nI][nPosPrefixo] + aTit[nI][nPosNumero] .AND. Len(aAuxFat) > 0
						cNumFat	:= aAuxFat[1][1]
					endif
				endif

				aAuxFat := U_TRETE016({aTit[nI]},cCli,cLojaCli,iif(lFatFat,4,3),cNumFat,lFatFat,,,,,cGet26)

				If Len(aAuxFat) > 0

					AAdd(aFatura,{aAuxFat[1][1],aAuxFat[1][2],aAuxFat[1][3],aAuxFat[1][4],aAuxFat[1][5],aAuxFat[1][6]})

					//Gera arquivo PDF da Fatura
					if lPDFFat
						cBlFuncFat := "U_"+cFImpFat+"(,cFilAnt,{{aAuxFat[1][1],aAuxFat[1][2],aAuxFat[1][3],aAuxFat[1][4],aAuxFat[1][5],aAuxFat[1][6]}},.T.,,,/*@__aArqPDF*/,cGet25)"
						&cBlFuncFat
					endif
				Endif

				cChvTit := aTit[nI][nPosPrefixo] + aTit[nI][nPosNumero]				
			Next nI

			//ordeno o array de faturas por cliente + numero + parcela
			ASort(aFatura,,,{|x,y| x[2] + x[3] + x[1] + x[5] < y[2] + y[3] + y[1] + y[5] })

			// Impressão de Faturas
			If MsgYesNo("Deseja imprimir a faturas?")
				cChvTit			:= aFatura[1][1]
				aAuxFat 		:= {}
				nQtdFat			:= Len(aFatura)

				oSay:cCaption := "Imprimindo faturas..."
				ProcessMessages()

				For nI := 1 To nQtdFat
					aadd(aAuxFat, {aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]} )

					if nI+1 <= nQtdFat
						cChvTit			:= aFatura[nI+1][1]
					endif

					if cChvTit <> aFatura[nI][1] .OR. nI == nQtdFat
						cBlFuncFat := "U_"+cFImpFat+"(oSay,cFilAnt,aAuxFat,.F.,.F.,,,cGet25)"
						&cBlFuncFat					
						aAuxFat := {}
					endif
				Next nI
			Endif

			// Gerar Boletos Bancários 
			If MsgYesNo("Deseja gerar o boleto?")
				cChvTit			:= aFatura[1][1]
				aAuxFat 		:= {}
				nQtdFat			:= Len(aFatura)

				oSay:cCaption := "Gerando boletos..."
				ProcessMessages()

				For nI := 1 To nQtdFat

					// Verifica se há geração de Boleto Bancário
					// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
					If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+aFatura[nI][2]+aFatura[nI][3]))
						If U88->U88_TPCOBR <> "B" //nao for Boleto Bancário
							LOOP
						Endif
					endif

					aadd(aAuxFat, {aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]} )

					if nI+1 <= nQtdFat
						cChvTit			:= aFatura[nI+1][1]
					endif

					if cChvTit <> aFatura[nI][1] .OR. nI == nQtdFat
						lGerBol := .T.

						SE1->(DbGoTop())
						SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						If SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]))

							aBoleto := {}

							AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
							AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
							AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
							AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
							AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
							AAdd(aBoleto,aAuxFat[len(aAuxFat)][5]) 					//Parcela - Ate
							AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
							AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
							AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
							AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
							AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
							AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
							AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
							AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
							AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
							//vou para ultima parcela
							SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]+aAuxFat[len(aAuxFat)][5]))
							AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
							AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
							AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
							AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
							AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
							AAdd(aBoleto,"") 										//Mensagem 1
							AAdd(aBoleto,"") 										//Mensagem 2

							//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,.T.,.F.)},'Aguarde','Imprimindo boleto bancário...')
							cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,.T.,.F.)}"
							FWMsgRun(, &cBlFuncBol ,'Aguarde','Gerando boleto bancário...')
						Endif

						aAuxFat := {}
					endif
				Next nI
			Endif

			if lGerBol .AND. MsgYesNo("Deseja imprimir o boleto?")
				cChvTit			:= aFatura[1][1]
				aAuxFat 		:= {}
				nQtdFat			:= Len(aFatura)

				oSay:cCaption := "Imprimindo boletos..."
				ProcessMessages()

				For nI := 1 To nQtdFat

					// Verifica se há geração de Boleto Bancário
					// U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
					If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+aFatura[nI][2]+aFatura[nI][3]))
						If U88->U88_TPCOBR <> "B" //nao for Boleto Bancário
							LOOP
						Endif
					endif

					aadd(aAuxFat, {aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]} )

					if nI+1 <= nQtdFat
						cChvTit			:= aFatura[nI+1][1]
					endif

					if cChvTit <> aFatura[nI][1] .OR. nI == nQtdFat
						lGerBol := .T.

						SE1->(DbGoTop())
						SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						If SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]))

							aBoleto := {}

							AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - De
							AAdd(aBoleto,SE1->E1_PREFIXO) 							//Prefixo - Ate
							AAdd(aBoleto,SE1->E1_NUM) 								//Numero - De
							AAdd(aBoleto,SE1->E1_NUM) 								//Numero - Ate
							AAdd(aBoleto,SE1->E1_PARCELA) 							//Parcela - De
							AAdd(aBoleto,aAuxFat[len(aAuxFat)][5]) 					//Parcela - Ate
							AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - De
							AAdd(aBoleto,SE1->E1_PORTADO) 							//Portador - Ate
							AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - De
							AAdd(aBoleto,SE1->E1_CLIENTE) 							//Cliente - Ate
							AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - De
							AAdd(aBoleto,SE1->E1_LOJA) 								//Loja - Ate
							AAdd(aBoleto,SE1->E1_EMISSAO) 							//Emissão - De
							AAdd(aBoleto,SE1->E1_EMISSAO)							//Emissão - Ate
							AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - De
							//vou para ultima parcela
							SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]+aAuxFat[len(aAuxFat)][5]))
							AAdd(aBoleto,DataValida(SE1->E1_VENCTO))				//Vencimento - Ate
							AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
							AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
							AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
							AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
							AAdd(aBoleto,"") 										//Mensagem 1
							AAdd(aBoleto,"") 										//Mensagem 2

							//FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
							cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,,.F.)}"
							FWMsgRun(, &cBlFuncBol ,'Aguarde','Imprimindo boleto bancário...')
						Endif

						aAuxFat := {}
					endif
				Next nI
			endif

			// Se houve alteração da database do sistema, retorna a data atual
			If lAltDt
				dDataBase := dDtBkp
			Endif

			If lGeraNF
				If MsgYesNo("Deseja gerar Nota Fiscal das faturas geradas?")
					MonitorNotas(aFatura)
				endif
			endif
			
			// Envio de e-mail com anexos do faturamento
			If lEnvArqs
				If MsgYesNo("Deseja enviar e-mail do faturamento?")

					oSay:cCaption := "Carregando dados para envio email..."
					ProcessMessages()

					cCli			:= aFatura[1][2]
					cLojaCli		:= aFatura[1][3]
					aAuxFat 		:= {}
					nQtdFat			:= Len(aFatura)

					For nI := 1 To nQtdFat
						aadd(aAuxFat, {aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]} )

						if nI+1 <= nQtdFat
							cCli			:= aFatura[nI+1][2]
							cLojaCli		:= aFatura[nI+1][3]
						endif

						if cCli+cLojaCli <> aFatura[nI][2]+aFatura[nI][3] .OR. nI == nQtdFat
							U_TRETE044(cFilAnt, aAuxFat )					
							aAuxFat := {}
						endif
					Next nI
				Endif
			Endif

			MsgInfo("Processo finalizado.","Atenção")
			
			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")

		Endif
	Else
		MsgInfo("Nenhum registro selecionado.","Atenção")
	Endif

	//Se houve alteração da database do sistema, retorna a data atual
	If lAltDt
		dDataBase := dDtBkp
	Endif

Return

//--------------------------------------------------------
// Realiza o faturamento parcelado
//--------------------------------------------------------
Static Function FatParc(oSay)

	Local nI
	Local nAux			:= 0

	Local lAltDt		:= .F.
	Local dDtBkp		:= CToD("")

	Local nRecSE1
	Local nVlrTit		

	Local oSay1, oSay2, oSay3
	Local oButton1, oButton2

	Local oCondPagto
	Local cCondPagto	:= Space(3)

	Private oParcFParc
	Private cParcFParc	:= Space(200)
	Private aParcelas	:= {}

	Static oDlgFParc

	If dGet24 <> dDataBase //Dt. referência diferente da Data atual
		dDtBkp		:= dDataBase
		dDataBase 	:= dGet24
		lAltDt 		:= .T.
	Endif

	//Verifica se data do movimento não é menor que data limite de
	//movimentacao no financeiro									
	If !DtMovFin()
		If lAltDt
			dDataBase := dDtBkp
		Endif
		Return
	Endif

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T. //Título selecionado

			If Val(StrTran(StrTran(cValToChar(aReg[nI][nPosSaldo]),".",""),",",".")) == 0 //Título baixado
				MsgInfo("O Título <"+AllTrim(aReg[nI][nPosNumero])+"> não se encontra em aberto, operação não permitida.","Atenção")
				If lAltDt
					dDataBase := dDtBkp
				Endif
				Return
			Endif

			nRecSE1 := aReg[nI][nPosRecno]
			nVlrTit := Val(StrTran(StrTran(cValToChar(aReg[nI][nPosSaldo]),".",""),",","."))

			nVlrTit += Val(StrTran(StrTran(cValToChar(aReg[nI][nPosAcresc]),".",""),",","."))
			nVlrTit -= Val(StrTran(StrTran(cValToChar(aReg[nI][nPosDecres]),".",""),",","."))
			nVlrTit += Val(StrTran(StrTran(cValToChar(aReg[nI][nPosVlAcess]),".",""),",","."))

			nAux++
		Endif
	Next nI

	If nAux == 0

		MsgInfo("Nenhum registro selecionado.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return

	ElseIf nAux > 1

		MsgInfo("O parcelamento é executado somente para 1 (um) título.","Atenção")

		If lAltDt
			dDataBase := dDtBkp
		Endif

		Return
	Else

		If PesqBol()
			If lAltDt
				dDataBase := dDtBkp
			Endif

			Return
		Endif

		DEFINE MSDIALOG oDlgFParc TITLE "Parcelar Título" From 000,000 TO 340,400 PIXEL

		@ 005, 010 SAY oSay1 PROMPT "Cond. pagto." SIZE 080, 007 OF oDlgFParc COLORS CLR_BLUE, 16777215 PIXEL
		@ 005, 055 MSGET oCondPagto VAR cCondPagto SIZE 040, 010 OF oDlgFParc COLORS 0, 16777215 PIXEL HASBUTTON F3 "SE4" Picture "@!" Valid (IIF(!Empty(cCondPagto), CondFParc(nVlrTit,cCondPagto), .T.))
		@ 018, 010 SAY oSay2 PROMPT "Parcelas" SIZE 080, 007 OF oDlgFParc COLORS 0, 16777215 PIXEL
		@ 018, 055 GET oParcFParc VAR cParcFParc MEMO SIZE 109, 122 OF oDlgFParc COLORS 0, 16777215 PIXEL
		oParcFParc:lReadOnly := .T.

		//Linha horizontal
		@ 144, 005 SAY oSay3 PROMPT Repl("_",190) SIZE 190, 007 OF oDlgFParc COLORS CLR_GRAY, 16777215 PIXEL

		@ 155, 110 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgFParc ACTION MsgRun("Processando...","Aguarde",{|| CParcFat(nRecSE1,cCondPagto,lAltDt,dDtBkp)}) PIXEL
		@ 155, 155 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgFParc ACTION FParcFat(lAltDt,dDtBkp) PIXEL

		ACTIVATE MSDIALOG oDlgFParc CENTERED

	EndIf

Return

//----------------------------------------------------------
//Gatilha informação das parcelas a partir da condicao 
//----------------------------------------------------------
Static Function CondFParc(_nVlrTit,_cCond)

	Local lRet 	:= .T.
	Local nI

	cParcFParc 	:= ""

	DbSelectArea("SE4")
	SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO

	If SE4->(DbSeek(xFilial("SE4")+_cCond))
		aParcelas := Condicao(_nVlrTit,_cCond,0.00,dDatabase,0.00,{},,0)

		For nI := 1 To Len(aParcelas)
			If nI == Len(aParcelas)
				cParcFParc := cParcFParc + cValToChar(nI) + "ª - " + DToC(aParcelas[nI][1]) + " - " + AllTrim(Transform(aParcelas[nI][2],"@E 9,999,999,999,999.99"))
			Else
				cParcFParc := cParcFParc + cValToChar(nI) + "ª - " + DToC(aParcelas[nI][1]) + " - " + AllTrim(Transform(aParcelas[nI][2],"@E 9,999,999,999,999.99")) + Chr(13)+Chr(10)
			Endif
		Next nI
	Else
		If Upper(AllTrim(ReadVar())) == "CCONDPAGTO"
			MsgInfo("Condição de Pagamento inválida.","Atenção")
			cParcFParc := ""
			aParcelas := {}
			lRet := .F.
		Endif
	Endif

	oParcFParc:Refresh()

Return lRet

//----------------------------------------------------------
// Processa faturamento parcelado
//----------------------------------------------------------
Static Function CParcFat(nRecSE1,cCondPagto,lAltDt,dDtBkp)

	Local lAux			:= .T.
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cBkpFil 		:= cFilAnt

	Private	lMsErroAuto := .F.
	Private	lMsHelpAuto := .T.

	If !Empty(cCondPagto)

		If MsgYesNo("Haverá o parcelamento do registro selecionado, deseja continuar?")
			
			DbSelectArea("SE1")
			SE1->(DbGoTo(nRecSE1))

			if lMVVFilOri
				cFilAnt := SE1->E1_FILORIG
			endif

			Begin Transaction

			//Exclui borderô
			ExcBord(nRecSE1)

			//Inclui novo(s) titulo(s)
			lAux := IncTit(2,nRecSE1, .T.)

			If lAux
				//Baixa o título atual
				lAux := BaixaTit(nRecSE1)
			Endif

			End Transaction

			If lAux
				MsgInfo("Parcelamento realizado com sucesso. Baixado o título atual e incluído novo(s) título(s).","Atenção")
				oDlgFParc:End()
				
				Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
			Endif
		EndIf
	Else
		MsgInfo("Campo [Cond. pagto.] obrigatório.","Atenção")
	Endif

	If lAltDt
		dDataBase := dDtBkp
	Endif

	cFilAnt := cBkpFil

Return

/***************************************/
Static Function FParcFat(lAltDt,dDtBkp)
/***************************************/

	If lAltDt
		dDataBase := dDtBkp
	Endif

	oDlgFParc:End()

Return

/********************************************************/
Static Function VisCf(_cFilial,_cCf,_cSerie,_cCli,_cLoja)
/********************************************************/

	Local aArea 		:= GetArea()
	Local aAreaSE1		:= SE1->(GetArea())
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cFilBkp		:= ""
	Local nI
	Local nCont			:= 0
	Local nRecSE1		:= 0

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.

			If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
				MsgInfo("Dentre os registros selecionados, há Fatura(s), visualização não permitida.","Atenção")
				Return
			Endif

			nRecSE1	:= aReg[nI][nPosRecno]
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		Return
	Endif

	If nCont > 1
		MsgInfo("A visualização da Venda deve ser realizada para um título de cada vez.","Atenção")
		Return
	Endif

	If !Empty(_cCf)

		dbSelectArea("SF2")
		SF2->(dbSetOrder(1))

		// verifico se verifico a filial de origem
		If lMVVFilOri .And. nRecSE1 > 0 

			// posiciono no registro da SE1
			SE1->(DbGoTo(nRecSE1))

			// pego a filial de origem
			_cFilial := SE1->E1_FILORIG

			// gravo a filial atual como backup
			cFilBkp := cFilAnt

			// atualizo o cFilant
			cFilAnt := _cFilial

		EndIf

		If SF2->(dbSeek(_cFilial+_cCf+_cSerie+_cCli+_cLoja))
			Mc090Visual("SF2",SF2->(Recno()),1)
		Else
			MsgInfo("Venda não localizada.","Atenção")
		Endif

		// caso estiver usando a variavel de backup da filial
		If !Empty(cFilBkp)
			cFilAnt := cFilBkp
		EndIf

	Endif

	RestArea(aAreaSE1)
	RestArea(aArea)

Return(Nil)

/***********************/
Static Function AltTit()
/***********************/

	Local nI
	Local nCont		:= 0
	Local cBkpOrigem := ""
	Local nRecSE1	:= 0

	Private lIntegracao := .F.
	Private cCadastro 	:= "Contas a Receber - Alterar"

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.

			nRecSE1	:= aReg[nI][nPosRecno]
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		Return
	Endif

	If nCont > 1
		MsgInfo("A alteração de Título deve ser realizada para um título de cada vez.","Atenção")
		Return
	Endif

	SE1->(DbSelectArea("SE1"))
	SE1->(DbGoTo(nRecSE1))

	INCLUI := .F.
	ALTERA := .T.

	cBkpOrigem := SE1->E1_ORIGEM

	If  Alltrim(SE1->E1_ORIGEM) == "LOJA701" .And. SE1->E1_TIPO $ 'CC |CD |PX |PD '
		//TITPGPIXCART - O título não pode ser alterado pois foi originado pela rotina de Venda Assistida e pago com PIX ou cartões de débito e crédito
		//apaga a origem para ser possível alteração/exclusão do titulo
		RecLock("SE1",.F.)
			SE1->E1_ORIGEM := ""
		SE1->(MsUnlock())
	EndIf

	FA040Alter("SE1",nRecSE1,4)

	//volta a origem 
	RecLock("SE1",.F.)
		SE1->E1_ORIGEM := cBkpOrigem
	SE1->(MsUnlock())

Return

/**************************/
Static Function AltSacTit()
/**************************/

	Local nI
	Local nCont		:= 0
	Local nRecSE1	:= 0

	For nI := 1 To Len(aReg)

		If aReg[nI][nPosMark] == .T.

			If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
				MsgInfo("Dentre os registros selecionados, há Fatura(s), operação não permitida.","Atenção")
				Return
			Else
				nRecSE1	:= aReg[nI][nPosRecno]
				nCont++
			Endif
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro selecionado.","Atenção")
		Return
	Endif

	If nCont > 1
		MsgInfo("A alteração de Título deve ser realizada para um título de cada vez.","Atenção")
		Return
	Endif

	SE1->(DbSelectArea("SE1"))
	SE1->(DbGoTo(nRecSE1))

	U_TRETA043(,,,,,SE1->(Recno()))

	Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")

Return

/***********************/
Static Function SelOpc()
/***********************/

	Local nOpc

	Local oRadio
	Local nRadio := 1
	Local aOptions := {"Alterar Data de Vencimento (vencimento único)","Reparcelar (múltiplos vencimentos)","Reparcelar (flexível)"}

	Local oSay1
	Local oButton1, oButton2

	Static oDlgOpc

	if ExistBlock("TR017CRN")
		aadd(aOptions,"Imprimir Contrato de Renegociação")
	endif

	DEFINE MSDIALOG oDlgOpc TITLE "Selecionar Opção" From 000,000 TO 140,300 PIXEL

	oRadio:= TRadMenu():New(005,005,aOptions,{|u|if(PCount()>0,nRadio:=u,nRadio)},oDlgOpc,,,,,,,,150,20,,,,.T.)

// Linha horizontal
	@ 044, 005 SAY oSay1 PROMPT Repl("_",140) SIZE 140, 007 OF oDlgOpc COLORS CLR_GRAY, 16777215 PIXEL

	@ 055, 060 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgOpc ACTION {||nOpc := nRadio,oDlgOpc:End()} PIXEL
	@ 055, 105 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgOpc ACTION {||nOpc := 0,oDlgOpc:End()} PIXEL

	ACTIVATE MSDIALOG oDlgOpc CENTERED

Return nOpc

/**************************************/
Static Function AltDtVenc(nRecSE1,aReg)
/**************************************/

	Local oGroup1, oGroup2
	Local oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12, oSay13, oSay14, oSay15, oSay16
	Local oButton1, oButton2

	Private oDtOrig
	Private dDtOrig 	:= CToD("")

	Private oSldOrig
	Private nSldOrig	:= 0

	Private oDtAtual
	Private dDtAtual 	:= dDataBase

	Private oDifOrig
	Private nDifOrig	:= 0

	Private oPercAtual
	Private nPercAtual	:= Round((GetMv("MV_TXPER")),0)

	Private oPercMuAtu
	Private nPercMuAtu	:= GetMv("MV_LJMULTA")

	Private oVlBolAtua
	Private nVlBolAtua	:= SuperGetMv("MV_XTXRENE",,0)

	Private oSldAtual
	Private nSldAtual	:= 0

	Private oDtNova
	Private dDtNova 	:= CToD("")

	Private oDifNova
	Private nDifNova	:= 0

	Private oPercNovo
	Private nPercNovo	:= Round((GetMv("MV_TXPER")),0)

	Private oPercMuNov
	Private nPercMuNov	:= GetMv("MV_LJMULTA")

	Private oVlBolNovo
	Private nVlBolNovo	:= SuperGetMv("MV_XTXRENE",,0)

	Private oDescNovo
	Private nDescNovo	:= 0

	Private oSldNovo
	Private nSldNovo	:= 0

	Static oDlgDt

	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecSE1))

	dDtOrig 	:= SE1->E1_VENCTO
	nSldOrig	:= SE1->E1_SALDO + SE1->E1_ACRESC - SE1->E1_DECRESC
	nSldOrig 	+= U_UFValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1,SE1->E1_TXMOEDA)

	nDifOrig	:= dDtAtual - dDtOrig

	If nDifOrig > 0
		nSldAtual	:= nSldOrig + ((nSldOrig * (nDifOrig * (nPercAtual / 30))) / 100) + ((nSldOrig * nPercMuAtu) / 100) + nVlBolAtua
	Else
		nSldAtual	:= nSldOrig
	Endif

	DEFINE MSDIALOG oDlgDt TITLE "Alterar Dt. Vencimento" From 000,000 TO 300,500 PIXEL

	@ 005, 005 GROUP oGroup1 TO 125, 120 PROMPT "Dados atuais" OF oDlgDt COLOR 0, 16777215 PIXEL
	@ 015, 010 SAY oSay1 PROMPT "Dt. Vencto. orig." SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 015, 055 MSGET oDtOrig VAR dDtOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"
	@ 028, 010 SAY oSay2 PROMPT "Saldo orig." SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 028, 055 MSGET oSldOrig VAR nSldOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	@ 041, 010 SAY oSay3 PROMPT "Dt. Atual" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 041, 055 MSGET oDtAtual VAR dDtAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"
	@ 054, 010 SAY oSay4 PROMPT "Dif. dias" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 054, 055 MSGET oDifOrig VAR nDifOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999,999"
	@ 067, 010 SAY oSay5 PROMPT "Tx juros % (mês)" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 067, 055 MSGET oPercAtual VAR nPercAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999.99"
	@ 080, 010 SAY oSay6 PROMPT "Tx multa %" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 080, 055 MSGET oPercAtual VAR nPercMuAtu SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999.99"
	@ 093, 010 SAY oSay7 PROMPT "Reenvio bol. (R$)" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 093, 055 MSGET oPercAtual VAR nVlBolAtua SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	@ 106, 010 SAY oSay8 PROMPT "Saldo atual" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 106, 055 MSGET oSldAtual VAR nSldAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

	@ 005, 130 GROUP oGroup2 TO 112, 245 PROMPT "Dados novos" OF oDlgDt COLOR 0, 16777215 PIXEL
	@ 015, 135 SAY oSay9 PROMPT "Dt. Vencimento" SIZE 080, 007 OF oGroup2 COLORS CLR_BLUE, 16777215 PIXEL
	@ 015, 180 MSGET oDtNova VAR dDtNova SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@D" Valid(IIF(!Empty(dDtNova),VldDtNova(dDtNova),.T.))
	@ 028, 135 SAY oSay10 PROMPT "Dif. dias" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 028, 180 MSGET oDifNova VAR nDifNova SIZE 060, 010 OF oGroup2 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999,999"
	@ 041, 135 SAY oSay11 PROMPT "Tx juros % (mês)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 041, 180 MSGET oPercNovo VAR nPercNovo SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 999.99" Valid(VldPercNovo(nPercNovo))
	@ 054, 135 SAY oSay12 PROMPT "Tx multa %" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 054, 180 MSGET oPercAtual VAR nPercMuNov SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 999.99" Valid(VldPercM(nPercMuNov))
	@ 067, 135 SAY oSay13 PROMPT "Reenvio bol. (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 067, 180 MSGET oPercAtual VAR nVlBolNovo SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99" Valid(VldVlBol(nVlBolNovo))
	@ 080, 135 SAY oSay14 PROMPT "Desconto (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 080, 180 MSGET oDescNovo VAR nDescNovo SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99" Valid(VldDescNovo(nDescNovo))
	@ 093, 135 SAY oSay15 PROMPT "Saldo" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 093, 180 MSGET oSldNovo VAR nSldNovo SIZE 060, 010 OF oGroup2 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

// Linha horizontal
	@ 124, 005 SAY oSay16 PROMPT Repl("_",240) SIZE 240, 007 OF oDlgDt COLORS CLR_GRAY, 16777215 PIXEL

	@ 135, 160 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgDt ACTION FWMsgRun(,{|oSay| ConfAlt(oSay,nRecSE1,aReg)},'Aguarde','Processando...') PIXEL
	@ 135, 205 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgDt ACTION oDlgDt:End() PIXEL

	ACTIVATE MSDIALOG oDlgDt CENTERED

Return

/**********************************/
Static Function VldDtNova(_dDtNova)
/**********************************/

	Local lRet := .T.

	If _dDtNova < dDtAtual
		MsgInfo("A Dt. Vencimento (nova) não pode ser inferior a Dt. Vencimento (atual).","Atenção")
		lRet :=  .F.
	Else
		nDifNova 	:= _dDtNova - dDtOrig
		nSldNovo	:= nSldOrig + ((nSldOrig * (nDifNova * (nPercNovo / 30))) / 100) + ((nSldOrig * nPercMuNov) / 100) + nVlBolNovo - nDescNovo

		oDifNova:Refresh()
		oSldNovo:Refresh()
	Endif

Return lRet

/**************************************/
Static Function VldPercNovo(_nPercNovo)
/**************************************/

	nSldNovo := nSldOrig + ((nSldOrig * (nDifNova * (_nPercNovo / 30))) / 100) + ((nSldOrig * nPercMuNov) / 100) + nVlBolNovo - nDescNovo

	oSldNovo:Refresh()

Return .T.

/*********************************/
Static Function VldPercM(_nPercMu)
/*********************************/

	nSldNovo := nSldOrig + ((nSldOrig * (nDifNova * (nPercNovo / 30))) / 100) + ((nSldOrig * _nPercMu) / 100) + nVlBolNovo - nDescNovo

	oSldNovo:Refresh()

Return .T.

/********************************/
Static Function VldVlBol(_nVlBol)
/********************************/

	nSldNovo := nSldOrig + ((nSldOrig * (nDifNova * (nPercNovo / 30))) / 100) + ((nSldOrig * nPercMuNov) / 100) + _nVlBol - nDescNovo

	oSldNovo:Refresh()

Return .T.

/**************************************/
Static Function VldDescNovo(_nDescNovo)
/**************************************/

	nSldNovo := nSldOrig + ((nSldOrig * (nDifNova * (nPercNovo / 30))) / 100) + ((nSldOrig * nPercMuNov) / 100) + nVlBolNovo - _nDescNovo

	oSldNovo:Refresh()

Return .T.

/*****************************************/
Static Function ConfAlt(oSay,nRecSE1,aReg)
/*****************************************/

	Local aFatura		:= {}
	Local lContinua		:= .T.
	Local _aAlcada		:= {}
	Local lAux
	Local aDadosFat		:= {}
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cBkpFil 		:= cFilAnt

	Private	lMsErroAuto := .F.
	Private	lMsHelpAuto := .T.

	If !Empty(dDtNova)

		DbSelectArea("SE1")
		SE1->(DbGoTo(nRecSE1))

		if lMVVFilOri
			cFilAnt := SE1->E1_FILORIG
		endif

		AAdd(aDadosFat,{SE1->E1_PREFIXO,;
								SE1->E1_NUM,;
								SE1->E1_PARCELA,;
								SE1->E1_TIPO})

		If nDescNovo > 0

			_aAlcada := {{"U16_FIL",xFilial("U16")},;
				{"U16_GRPCLI",Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_GRPVEN")},;
				{"U16_CLIENT",SE1->E1_CLIENTE},;
				{"U16_SEGMEN",Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_SATIV1")},;
				{"U16_VALDES",nDescNovo},;
				{"U16_FORMPG",AllTrim(SE1->E1_TIPO)}}

			//If SuperGetMv( "ES_ALCADA" , .F. , .F.,) .And. SuperGetMv( "ES_ALCU16" , .F. , .F.,)
			//	lContinua := U_LJ004VAL("U16",_aAlcada) //Verifica alçada
			//EndIf
		Endif

		If lContinua

			oSay:cCaption := "Processando..."
			ProcessMessages()

			Begin Transaction

				// Exclui borderô
				ExcBord(nRecSE1)

				// Verifica versão da fatura
				If !Empty(SE1->E1_NUMLIQ) // Liquidação

					// Reliquida
					aFatura := U_TRETE016(;
						{aReg},;
						aReg[nPosCliente],;
						aReg[nPosLoja],;
						4,;
						,;
						,;
						,;
						dDtNova,;
						IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0),;
						IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0),;
						cGet26) //"RENEG. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""

					If Len(aFatura) > 0
						// Verifica se o Log de Renegociacao consta ativado
						If lLogRen
							U_TRETE040(3,aDadosFat)
						EndIf

						MsgInfo("Data de Vencimento alterada com sucesso. Baixado o Título atual e incluído novo Título com as novas diretrizes.","Atenção")
						oDlgDt:End()
						
					Endif

				Else // Fatura

					//Inclui novo(s) titulo(s)
					lAux := IncTit(1,nRecSE1)

					If lAux

						//Baixa o título atual
						lAux := BaixaTit(nRecSE1)
					Endif

					MsgInfo("Data de Vencimento alterada com sucesso. Baixado o Título atual e incluído novo Título com as novas diretrizes.","Atenção")
					oDlgDt:End()
					
				EndIf

			End Transaction
		Else
			MsgInfo("Não há alçada para emissão de desconto. Favor entrar em contato com a gerência.","Atenção")
		Endif
	Else
		MsgInfo("Campo <Dt. Vencimento (nova)> obrigatório.","Atenção")
	Endif

	cFilAnt := cBkpFil

Return

/*************************************/
Static Function Parcelar(nRecSE1,aReg)
/*************************************/

	Local oGroup1, oGroup2
	Local oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12, oSay13, oSay14, oSay15, oSay16, oSay17
	Local oButton1, oButton2

	Private oDtOrig
	Private dDtOrig 	:= CToD("")

	Private oSldOrig
	Private nSldOrig	:= 0

	Private oDtAtual
	Private dDtAtual 	:= dDataBase

	Private oDifOrig
	Private nDifOrig	:= 0

	Private oPercAtual
	Private nPercAtual	:= Round((GetMv("MV_TXPER")),0)

	Private oPercMuAtu
	Private nPercMuAtu	:= GetMv("MV_LJMULTA")

	Private oVlBolAtua
	Private nVlBolAtua	:= SuperGetMv("MV_XTXRENE",,0)

	Private oSldAtual
	Private nSldAtual	:= 0

	Private oCondPagto
	Private cCondPagto	:= Space(TamSX3("E4_CODIGO")[1])

	Private oTpAmort
	Private nTpAmort 	:= 1 //SAC

	Private oParcela
	Private cParcela	:= Space(200)

	Private oPercNovo
	Private nPercNovo	:= Round((GetMv("MV_TXPER")),0)

	Private oPercMuNov
	Private nPercMuNov	:= GetMv("MV_LJMULTA")

	Private oVlBolNovo
	Private nVlBolNovo	:= SuperGetMv("MV_XTXRENE",,0)

	Private oDescNovo
	Private nDescNovo	:= 0

	Private oSldNovo
	Private nSldNovo	:= 0

	Private aParcOrig	:= {}
	Private aParcelas	:= {}

	Static oDlgParc

	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecSE1))

	dDtOrig 	:= SE1->E1_VENCTO
	nSldOrig	:= SE1->E1_SALDO + SE1->E1_ACRESC - SE1->E1_DECRESC
	nSldOrig 	+= U_UFValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1,SE1->E1_TXMOEDA)
	nDifOrig	:= dDtAtual - dDtOrig

	If nDifOrig > 0
		nSldAtual	:= nSldOrig + ((nSldOrig * (nDifOrig * (nPercAtual / 30))) / 100) + ((nSldOrig * nPercMuAtu) / 100) + nVlBolAtua
	Else
		nSldAtual	:= nSldOrig
	Endif

	DEFINE MSDIALOG oDlgParc TITLE "Parcelar Título" From 000,000 TO 340,600 PIXEL

	@ 005, 005 GROUP oGroup1 TO 124, 120 PROMPT "Dados atuais" OF oDlgParc COLOR 0, 16777215 PIXEL
	@ 015, 010 SAY oSay1 PROMPT "Dt. Vencto. orig." SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 015, 055 MSGET oDtOrig VAR dDtOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"
	@ 028, 010 SAY oSay2 PROMPT "Saldo orig." SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 028, 055 MSGET oSldOrig VAR nSldOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	@ 041, 010 SAY oSay3 PROMPT "Dt. Atual" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 041, 055 MSGET oDtAtual VAR dDtAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"
	@ 054, 010 SAY oSay4 PROMPT "Dif. dias" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 054, 055 MSGET oDifOrig VAR nDifOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999,999"
	@ 067, 010 SAY oSay5 PROMPT "Tx juros % (mês)" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 067, 055 MSGET oPercAtual VAR nPercAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999.99"
	@ 080, 010 SAY oSay6 PROMPT "Tx multa %" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 080, 055 MSGET oPercMuAtu VAR nPercMuAtu SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999.99"
	@ 093, 010 SAY oSay7 PROMPT "Reenvio bol. (R$)" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 093, 055 MSGET oVlBolAtua VAR nVlBolAtua SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	@ 106, 010 SAY oSay8 PROMPT "Saldo atual" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 106, 055 MSGET oSldAtual VAR nSldAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

	@ 005, 130 GROUP oGroup2 TO 150, 295 PROMPT "Dados novos" OF oDlgParc COLOR 0, 16777215 PIXEL
	@ 015, 135 SAY oSay9 PROMPT "Cond. pagto." SIZE 080, 007 OF oGroup2 COLORS CLR_BLUE, 16777215 PIXEL
	@ 015, 180 MSGET oCondPagto VAR cCondPagto SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL HASBUTTON F3 "SE4" Picture "@!" Valid(IIF(!Empty(cCondPagto),VldCond(cCondPagto,nPercNovo,nPercMuNov,nVlBolNovo,nDescNovo),.T.))
	@ 028, 135 SAY oSay10 PROMPT "Tipo armortização" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 028, 180 MSCOMBOBOX oTpAmort VAR nTpAmort ITEMS {"SAC","Tabela Price"} SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Valid(VldCond(cCondPagto,nPercNovo,nPercMuNov,nVlBolNovo,nDescNovo))
	@ 041, 135 SAY oSay11 PROMPT "Tx juros % (mês)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 041, 180 MSGET oPercNovo VAR nPercNovo SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 999.99" Valid(VldCond(cCondPagto,nPercNovo,nPercMuNov,nVlBolNovo,nDescNovo))
	@ 054, 135 SAY oSay12 PROMPT "Tx multa %" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 054, 180 MSGET oPercMuNov VAR nPercMuNov SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 999.99" Valid(VldCond(cCondPagto,nPercNovo,nPercMuNov,nVlBolNovo,nDescNovo))
	@ 067, 135 SAY oSay13 PROMPT "Reenvio bol. (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 067, 180 MSGET oVlBolNovo VAR nVlBolNovo SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99" Valid(VldCond(cCondPagto,nPercNovo,nPercMuNov,nVlBolNovo,nDescNovo))
	@ 080, 135 SAY oSay14 PROMPT "Parcelas" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 080, 180 GET oParcela VAR cParcela MEMO SIZE 109, 033 OF oGroup2 COLORS 0, 16777215 PIXEL
	oParcela:lReadOnly := .T.
	@ 114, 135 SAY oSay15 PROMPT "Desconto (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 114, 180 MSGET oDescNovo VAR nDescNovo SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99" Valid(VldCond(cCondPagto,nPercNovo,nPercMuNov,nVlBolNovo,nDescNovo))
	@ 127, 135 SAY oSay16 PROMPT "Saldo" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 127, 180 MSGET oSldNovo VAR nSldNovo SIZE 060, 010 OF oGroup2 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

// Linha horizontal
	@ 144, 005 SAY oSay17 PROMPT Repl("_",290) SIZE 290, 007 OF oDlgParc COLORS CLR_GRAY, 16777215 PIXEL

	@ 155, 210 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgParc ACTION FWMsgRun(,{|oSay| ConfParc(oSay,nRecSE1,aReg)},'Aguarde','Processando...') PIXEL
	@ 155, 255 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgParc ACTION oDlgParc:End() PIXEL

	ACTIVATE MSDIALOG oDlgParc CENTERED

Return

/****************************************************************/
Static Function VldCond(_cCond,_nPercJur,_nPercMu,_nVlBol,_nDesc)
/****************************************************************/

	Local lRet 		:= .T.

	Local nI
	Local nSld		:= 0

	Local nJur		:= 0
	Local nCoef		:= 0
	Local nAmort	:= 0

	cParcela 		:= ""

	DbSelectArea("SE4")
	SE4->(DbSetOrder(1)) // E4_FILIAL+E4_CODIGO

	If SE4->(DbSeek(xFilial("SE4")+_cCond))

		aParcelas 	:= Condicao(nSldOrig + ((nSldOrig * _nPercMu) / 100) + _nVlBol - _nDesc,_cCond,0.00,dDatabase,0.00,{},,0)
		aParcOrig 	:= Condicao(nSldOrig,_cCond,0.00,dDatabase,0.00,{},,0)

		If oTpAmort:nAt == 2 //Tabela Price

			For nI := 1 To Len(aParcelas)

				nJur 	:= _nPercJur / 100
				nCoef 	:= (nJur * ((1 + nJur) ^ Len(aParcelas))) / (((1 + nJur) ^ Len(aParcelas)) - 1)

				aParcelas[nI][2] := Round( nCoef * (nSldOrig + ((nSldOrig * _nPercMu) / 100) + _nVlBol - _nDesc), TamSX3("E1_VALOR")[2])

				If nI == Len(aParcelas)
					cParcela := cParcela + cValToChar(ni) + "ª - " + DToC(aParcelas[nI][1]) + " - " + AllTrim(Transform(aParcelas[nI][2],"@E 9,999,999,999,999.99"))
				Else
					cParcela := cParcela + cValToChar(ni) + "ª - " + DToC(aParcelas[nI][1]) + " - " + AllTrim(Transform(aParcelas[nI][2],"@E 9,999,999,999,999.99")) + Chr(13)+Chr(10)
				Endif

				nSld += aParcelas[nI][2]
			Next

		Else // SAC

			nAmort := (nSldOrig + ((nSldOrig * _nPercMu) / 100) + _nVlBol - _nDesc) / Len(aParcelas)

			For nI := 1 To Len(aParcelas)

				If nI == 1
					aParcelas[nI][2] := Round(nAmort + ((nSldOrig + ((nSldOrig * _nPercMu) / 100) + _nVlBol - _nDesc) * (_nPercJur / 100)) , TamSX3("E1_VALOR")[2])
				Else
					aParcelas[nI][2] := Round(nAmort + (((nSldOrig + ((nSldOrig * _nPercMu) / 100) + _nVlBol - _nDesc) - (nAmort * (nI - 1))) * (_nPercJur / 100)) , TamSX3("E1_VALOR")[2])
				Endif

				If nI == Len(aParcelas)
					cParcela := cParcela + cValToChar(nI) + "ª - " + DToC(aParcelas[nI][1]) + " - " + AllTrim(Transform(aParcelas[nI][2],"@E 9,999,999,999,999.99"))
				Else
					cParcela := cParcela + cValToChar(nI) + "ª - " + DToC(aParcelas[nI][1]) + " - " + AllTrim(Transform(aParcelas[nI][2],"@E 9,999,999,999,999.99")) + Chr(13)+Chr(10)
				Endif

				nSld += aParcelas[nI][2]
			Next
		Endif

		nSldNovo := nSld
		oSldNovo:Refresh()
	Else
		If Upper(AllTrim(ReadVar())) == "CCONDPAGTO"
			MsgInfo("Condição de Pagamento inválida.","Atenção")
			aParcelas := {}
			lRet := .F.
		Endif
	Endif

Return lRet

/******************************************/
Static Function ConfParc(oSay,nRecSE1,aReg)
/******************************************/

	Local aFatura		:= {}
	Local lContinua		:= .T.
	Local lAux
	Local aDadosFat		:= {}
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cBkpFil 		:= cFilAnt

	Private	lMsErroAuto := .F.
	Private	lMsHelpAuto := .T.

	If !Empty(cCondPagto)

		DbSelectArea("SE1")
		SE1->(DbGoTo(nRecSE1))

		if lMVVFilOri
			cFilAnt := SE1->E1_FILORIG
		endif

		AAdd(aDadosFat,{SE1->E1_PREFIXO,;
								SE1->E1_NUM,;
								SE1->E1_PARCELA,;
								SE1->E1_TIPO})

		If nDescNovo > 0

			_aAlcada := {{"U16_FIL",xFilial("U16")},;
				{"U16_GRPCLI",Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_GRPVEN")},;
				{"U16_CLIENT",SE1->E1_CLIENTE},;
				{"U16_SEGMEN",Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_SATIV1")},;
				{"U16_VALDES",nDescNovo},;
				{"U16_FORMPG",AllTrim(SE1->E1_TIPO)}}

			//If SuperGetMv( "ES_ALCADA" , .F. , .F.,) .And. SuperGetMv( "ES_ALCU16" , .F. , .F.,)
			//	lContinua := U_LJ004VAL("U16",_aAlcada) //Verifica alçada
			//EndIf
		Endif

		If lContinua

			oSay:cCaption := "Processando..."
			ProcessMessages()

			Begin Transaction

				// Exclui borderô
				ExcBord(nRecSE1)

				//Ajusto o acrescimoe decrescimo do titulo, para evitar erros de diferença de valor na renegociação
				AjustaValor(IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0), IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0))

				// Verifica versão da fatura
				If !Empty(SE1->E1_NUMLIQ) // Liquidação

					// Reliquida
					aFatura := U_TRETE016(;
						{aReg},;
						aReg[nPosCliente],;
						aReg[nPosLoja],;
						4,;
						,;
						,;
						,;
						CToD(""),;
						IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0),;
						IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0),;
						cGet26,; //"RENEG. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""
						aParcelas,;
						aParcOrig,;
						,;
						nSldOrig)

					If Len(aFatura) > 0
						// Verifica se o Log de Renegociacao consta ativado
						If lLogRen
							U_TRETE040(3,aDadosFat)
						EndIf

						MsgInfo("Reparcelamento realizado com sucesso. Baixado o Título atual e incluído novo(s) Título(s) com as novas diretrizes.","Atenção")
						oDlgParc:End()
						
					Endif

				Else // Fatura
	
					//Inclui novo(s) titulo(s)
					lAux := IncTit(2,nRecSE1)

					If lAux

						//Baixa o título atual
						lAux := BaixaTit(nRecSE1)

						MsgInfo("Reparcelamento realizado com sucesso. Baixado o Título atual e incluído novo(s) Título(s) com as novas diretrizes.","Atenção")
						oDlgParc:End()
						

					Endif
					
				EndIf

			End Transaction
		Else
			MsgInfo("Não há alçada para emissão de desconto. Favor entrar em contato com a gerência.","Atenção")
		Endif
	Else
		MsgInfo("Campo <Cond. Pagto.> obrigatório.","Atenção")
	Endif

	cFilAnt := cBkpFil

Return

/*************************************/
Static Function ParcFlex(nRecSE1,aReg)
/*************************************/

	Local oGroup1, oGroup2
	Local oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12
	Local oButton1, oButton2

	Private oDtOrig
	Private dDtOrig 	:= CToD("")

	Private oSldOrig
	Private nSldOrig	:= 0

	Private oDtAtual
	Private dDtAtual 	:= dDataBase

	Private oDifOrig
	Private nDifOrig	:= 0

	Private oPercAtual
	Private nPercAtual	:= Round((GetMv("MV_TXPER")),0)

	Private oPercMuAtu
	Private nPercMuAtu	:= GetMv("MV_LJMULTA")

	Private oVlBolAtua
	Private nVlBolAtua	:= SuperGetMv("MV_XTXRENE",,0)

	Private oSldAtual
	Private nSldAtual	:= 0

	Private oQtdParc
	Private nQtdParc	:= 0

	Private oSldNovo
	Private nSldNovo	:= 0

	Private aParcOrig	:= {}
	Private aParcelas	:= {}

	Private oGet1

	Static oDlgPFlex

	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecSE1))

	dDtOrig 	:= SE1->E1_VENCTO
	nSldOrig	:= SE1->E1_SALDO + SE1->E1_ACRESC - SE1->E1_DECRESC
	nSldOrig 	+= U_UFValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1,SE1->E1_TXMOEDA)
	nDifOrig	:= dDtAtual - dDtOrig

	If nDifOrig > 0
		nSldAtual	:= nSldOrig + ((nSldOrig * (nDifOrig * (nPercAtual / 30))) / 100) + ((nSldOrig * nPercMuAtu) / 100) + nVlBolAtua
	Else
		nSldAtual	:= nSldOrig
	Endif

	DEFINE MSDIALOG oDlgPFlex TITLE "Parcelar Título" From 000,000 TO 340,600 PIXEL

	@ 005, 005 GROUP oGroup1 TO 124, 120 PROMPT "Dados atuais" OF oDlgPFlex COLOR 0, 16777215 PIXEL
	@ 015, 010 SAY oSay1 PROMPT "Dt. Vencto. orig." SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 015, 055 MSGET oDtOrig VAR dDtOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"
	@ 028, 010 SAY oSay2 PROMPT "Saldo orig." SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 028, 055 MSGET oSldOrig VAR nSldOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	@ 041, 010 SAY oSay3 PROMPT "Dt. Atual" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 041, 055 MSGET oDtAtual VAR dDtAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"
	@ 054, 010 SAY oSay4 PROMPT "Dif. dias" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 054, 055 MSGET oDifOrig VAR nDifOrig SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999,999"
	@ 067, 010 SAY oSay5 PROMPT "Tx juros % (mês)" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 067, 055 MSGET oPercAtual VAR nPercAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999.99"
	@ 080, 010 SAY oSay6 PROMPT "Tx multa %" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 080, 055 MSGET oPercMuAtu VAR nPercMuAtu SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 999.99"
	@ 093, 010 SAY oSay7 PROMPT "Reenvio bol. (R$)" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 093, 055 MSGET oVlBolAtua VAR nVlBolAtua SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
	@ 106, 010 SAY oSay8 PROMPT "Saldo atual" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 106, 055 MSGET oSldAtual VAR nSldAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

	@ 005, 130 GROUP oGroup2 TO 150, 295 PROMPT "Dados novos" OF oDlgPFlex COLOR 0, 16777215 PIXEL

	@ 015, 135 SAY oSay9 PROMPT "Parcelas" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL

	oGet1 := GetDados1()
	oGet1:oBrowse:bChange := {|| U_TRETE17A()}

	@ 114, 135 SAY oSay10 PROMPT "Qtd. parcelas" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 114, 180 MSGET oQtdParc VAR nQtdParc SIZE 060, 010 OF oGroup2 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999"
	@ 127, 135 SAY oSay11 PROMPT "Saldo" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 127, 180 MSGET oSldNovo VAR nSldNovo SIZE 060, 010 OF oGroup2 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

// Linha horizontal
	@ 144, 005 SAY oSay12 PROMPT Repl("_",290) SIZE 290, 007 OF oDlgPFlex COLORS CLR_GRAY, 16777215 PIXEL

	/*/
	Pablo Nunes - 27/01/2022
	Ajuste para atualizar o "Saldo" (variável nSldNovo): adicionado a função U_TRETE17A()
	Ao confirmar a tela, caso não tenha atualizado a liquidação fica com valor menor do que a soma das parcelas, gerando uma NCC indevidamente.
	CHAMADO: POSTO-271 - Ncc gerada ao utilizar reparcelamento
	/*/
	
	@ 155, 210 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgPFlex ACTION FWMsgRun(,{|oSay| U_TRETE17A(), ConfPFlex(oSay,nRecSE1,aReg)},'Aguarde','Processando...') PIXEL
	@ 155, 255 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgPFlex ACTION oDlgPFlex:End() PIXEL

	ACTIVATE MSDIALOG oDlgPFlex CENTERED

Return

/**************************/
Static Function GetDados1()
/**************************/

	Local nX
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}

	Local aFields 		:= {"PARC","DTVENC","VALOR"}
	Local aAlterFields 	:= {"DTVENC","VALOR"}

	For nX := 1 to Len(aFields)

		If aFields[nX] == "PARC"
			AAdd(aHeaderEx, {"Parcela","PARC","@!",4,,"","€€€€€€€€€€€€€€","C","","","",""})
		ElseIf aFields[nX] == "DTVENC"
			AAdd(aHeaderEx, {"Dt. Vencto.","DTVENC","",8,,"","€€€€€€€€€€€€€€","D","","","",""})
		ElseIf aFields[nX] == "VALOR"
			AAdd(aHeaderEx, {"Valor","VALOR","@E 9,999,999,999,999.99",16,2,"","€€€€€€€€€€€€€€","N","","","",""})
		Endif
	Next

	For nX := 1 To Len(aFields)
		Do Case
		Case aFields[nX] == "PARC"
			AAdd(aFieldFill, "0001")

		Case aFields[nX] == "DTVENC"
			AAdd(aFieldFill, CToD(""))

		Case aFields[nX] == "VALOR"
			AAdd(aFieldFill, 0)
		EndCase
	Next

	AAdd(aFieldFill, .F.)
	AAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(026,135,108,287,GD_INSERT+GD_DELETE+GD_UPDATE,"U_TRETE17B","AllwaysTrue","+PARC",aAlterFields,,999,;
		"AllwaysTrue","","U_TRETE17A",oDlgPFlex,aHeaderEx,aColsEx)

/**********************/
User Function TRETE17B()
/**********************/

	Local lRet			:= .T.

	Local nPosDtVenc 	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="DTVENC"})
	Local nPosValor 	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="VALOR"})

	If oGet1:aCols[oGet1:nAT,Len(oGet1:aHeader)+1] == .F. // Não estiver deletado

		If Empty(oGet1:aCols[oGet1:nAT,nPosDtVenc])

			MsgInfo("Campo <Dt. Vencto.> obrigatório.>","Atenção")
			lRet := .F.
		Endif

		If lRet

			If Empty(oGet1:aCols[oGet1:nAT,nPosValor])

				MsgInfo("Campo <Valor> obrigatório.","Atenção")
				lRet := .F.
			Endif
		Endif
	Endif

Return lRet

/***********************/
User Function TRETE17A()
/***********************/

	Local nI

	nQtdParc := 0
	nSldNovo := 0

	For nI := 1 To Len(oGet1:aCols)

		If oGet1:aCols[nI,Len(oGet1:aHeader)+1] == .F. // Não estiver deletado

			If !Empty(oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="VALOR"})])

				nQtdParc++
				nSldNovo += oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="VALOR"})]
			Endif
		Endif
	Next

	oQtdParc:Refresh()
	oSldNovo:Refresh()

Return .T.

/*******************************************/
Static Function ConfPFlex(oSay,nRecSE1,aReg)
/*******************************************/

	Local aFatura		:= {}
	Local nI
	Local aParcMult		:= {}
	Local lAux
	Local aDadosFat		:= {}
	Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
	Local cBkpFil 		:= cFilAnt

	Private	lMsErroAuto := .F.
	Private	lMsHelpAuto := .T.

	If Len(oGet1:aCols) > 0

		DbSelectArea("SE1")
		SE1->(DbGoTo(nRecSE1))

		if lMVVFilOri
			cFilAnt := SE1->E1_FILORIG
		endif

		AAdd(aDadosFat,{SE1->E1_PREFIXO,;
								SE1->E1_NUM,;
								SE1->E1_PARCELA,;
								SE1->E1_TIPO})

		oSay:cCaption := "Processando..."
		ProcessMessages()

		Begin Transaction

			// Exclui borderô
			ExcBord(nRecSE1)

			//Ajusto o acrescimoe decrescimo do titulo, para evitar erros de diferença de valor na renegociação
			AjustaValor(IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0), IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0))

			For nI := 1 To Len(oGet1:aCols)

				If oGet1:aCols[nI,Len(oGet1:aHeader)+1] == .F. // Não estiver deletado

					If !Empty(oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})])

						AAdd(aParcMult,{oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="DTVENC"})],;
							oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})]})
					EndIf
				EndIf
			Next nI

			// Verifica versão da fatura
			If !Empty(SE1->E1_NUMLIQ) // Liquidação

				//Reliquida
				aFatura := U_TRETE016(;
					{aReg},;
					aReg[nPosCliente],;
					aReg[nPosLoja],;
					4,;
					,;
					,;
					,;
					CToD(""),;
					IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0),;
					IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0),;
					cGet26,; //"RENEG. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""
					aParcelas,;
					aParcOrig,;
					aParcMult,;
					nSldOrig)

				If Len(aFatura) > 0
					// Verifica se o Log de Renegociacao consta ativado
					If lLogRen
						U_TRETE040(3,aDadosFat)
					EndIf
					
					MsgInfo("Reparcelamento realizado com sucesso. Baixado o Título atual e incluído novo(s) Título(s) com as novas diretrizes.","Atenção")
					oDlgPFlex:End()
					
				Endif

			Else // Fatura

				//Inclui novo(s) titulo(s)
				lAux := IncTit(3,nRecSE1)

				If lAux
					//Baixa o título atual
					lAux := BaixaTit(nRecSE1)
				Endif

				MsgInfo("Reparcelamento realizado com sucesso. Baixado o Título atual e incluído novo(s) Título(s) com as novas diretrizes.","Atenção")
				oDlgPFlex:End()
				
			EndIf
		End Transaction
	Else
		MsgInfo("Obrigatoriamente deve ser incluída uma ou mais parcelas.","Atenção")
	Endif

	cFilAnt := cBkpFil

Return

/*******************************/
Static Function ExcBord(nRecSE1)
/*******************************/

// Se houver borderô associado, exclui
	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecSE1))

	DbSelectArea("SEA")
	SEA->(DbSetOrder(1)) // EA_FILIAL+EA_NUMBOR+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA

	If SEA->(DbSeek(xFilial("SEA")+SE1->E1_NUMBOR+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))

		RecLock("SEA")
		SEA->(DbDelete())
		SEA->(MsUnlock())

		SE1->(DbGoTo(nRecSE1))
		RecLock("SE1")
		SE1->E1_SITUACA	:= "0"
		SE1->E1_OCORREN	:= ""
		SE1->E1_NUMBOR	:= ""
		SE1->E1_DATABOR	:= CToD("")
		SE1->(MsUnLock())
	Endif

Return

/************************/
Static Function PesqBol()
/************************/

	Local nI
	Local lRet := .F.

	DbSelectArea("SE1")

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T.

			SE1->(DbGoTo(aReg[nI][nPosRecno]))

			If SE1->E1_SITUACA == "1" // Cob. simples (Borderô)
				MsgInfo("O título "+AllTrim(aReg[nI][nPosNumero])+" selecionado possui Boleto/Borderô relacionado, operação não permitida.","Atenção")
				lRet := .T.
				Exit
			Endif
		Endif
	Next

Return lRet

/**************************************************/
Static Function PesqNfCf(cFil,cPref,cTit,cParc,cTp)
/**************************************************/

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYNFCF") > 0
		QRYNFCF->(dbCloseArea())
	Endif

	cQry := "SELECT SF2.F2_NFCUPOM"
	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1, "+RetSqlName("SF2")+" SF2"
	cQry += CRLF + " WHERE SE1.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " AND SF2.D_E_L_E_T_	<> '*'"

	If cFil == Nil
		cQry += CRLF + " AND SE1.E1_FILIAL 	= '"+xFilial("SE1")+"'"
		cQry += CRLF + " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"
	Else
		cQry += CRLF + " AND SE1.E1_FILIAL 	= '"+cFil+"'"
		cQry += CRLF + " AND SF2.F2_FILIAL 	= '"+cFil+"'"
	Endif

	cQry += CRLF + " AND SE1.E1_FILIAL		= SF2.F2_FILIAL"
	cQry += CRLF + " AND SE1.E1_NUM		= SF2.F2_DOC"
	cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
	cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
	cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"
	cQry += CRLF + " AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += CRLF + " AND SE1.E1_NUM		= '"+cTit+"'"
	cQry += CRLF + " AND SE1.E1_PARCELA	= '"+cParc+"'"
	cQry += CRLF + " AND SE1.E1_TIPO		= '"+cTp+"'"

	cQry += CRLF + " ORDER BY 1"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETE017.txt",cQry)
	TcQuery cQry NEW Alias "QRYNFCF"

	While QRYNFCF->(!EOF())

		If !Empty(QRYNFCF->F2_NFCUPOM)
			lRet := .T.
			Exit
		Endif

		QRYNFCF->(DbSkip())
	EndDo

	If Select("QRYNFCF") > 0
		QRYNFCF->(dbCloseArea())
	Endif

Return lRet

/*************************************************/
Static Function PesqCxAbe(_nRecNo)
/*************************************************/

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYCX") > 0
		QRYCX->(dbCloseArea())
	Endif

	cQry := "SELECT 1 "
	cQry += CRLF + " FROM "+RetSqlName("SL1")+" SL1 "
	cQry += CRLF + " INNER JOIN "+RetSqlName("SE1")+" SE1 ON ( "
	cQry += CRLF + " 	SE1.D_E_L_E_T_ = SL1.D_E_L_E_T_ "
	cQry += CRLF + " 	AND E1_FILIAL = L1_FILIAL "
	cQry += CRLF + " 	AND E1_PREFIXO = L1_SERIE "
	cQry += CRLF + " 	AND E1_NUM = L1_DOC "
	//cQry += CRLF + " 	AND E1_CLIENTE = L1_CLIENTE "
	//cQry += CRLF + " 	AND E1_LOJA = L1_LOJA "
	cQry += CRLF + " 	AND E1_EMISSAO = L1_EMISNF "
	cQry += CRLF + " 	) "
	cQry += CRLF + " INNER JOIN "+RetSqlName("SLW")+" SLW ON ( "
	cQry += CRLF + " 	SLW.D_E_L_E_T_ = SL1.D_E_L_E_T_ "
	cQry += CRLF + " 	AND LW_FILIAL = L1_FILIAL "
	cQry += CRLF + " 	AND LW_OPERADO = L1_OPERADO "
	cQry += CRLF + " 	AND LW_NUMMOV = L1_NUMMOV "
	cQry += CRLF + " 	AND RTRIM(LW_PDV) = RTRIM(L1_PDV) "
	cQry += CRLF + " 	AND LW_ESTACAO  = L1_ESTACAO "
	cQry += CRLF + " 	AND ( (L1_EMISNF+SUBSTRING(L1_HORA,1,5) BETWEEN LW_DTABERT+LW_HRABERT AND LW_DTFECHA+LW_HRFECHA) "
	cQry += CRLF + "      OR (LW_DTFECHA = ' ' AND L1_EMISNF+SUBSTRING(L1_HORA,1,5) >= LW_DTABERT+LW_HRABERT) )" //caixas nao fechados
	cQry += CRLF + " ) "
	cQry += CRLF + " WHERE SL1.D_E_L_E_T_ = ' ' "
	cQry += CRLF + " AND LW_CONFERE <> '1' "//-- diferente de 'Caixa Conferido'
	cQry += CRLF + " AND SE1.R_E_C_N_O_ = '"+alltrim(str(_nRecNo))+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETE017.txt",cQry)
	TcQuery cQry NEW Alias "QRYCX"

	If QRYCX->(!EOF())
		lRet := .T. //titulo pertece a um caixa não conferido
	Endif

	If Select("QRYCX") > 0
		QRYCX->(dbCloseArea())
	Endif

Return lRet

/*********************************/
Static Function ValDuplic()
/*********************************/
	Local lRet := .F.
	Local cQry := ""
	Local cDodSerAbst := ""
	Local cSGBD	:= AllTrim(Upper(TcGetDb())) // -- Banco de dados atulizado (Para embientes TOP) 			 	

	If Select("QRYDUP") > 0
		QRYDUP->(dbCloseArea())
	Endif

	//considera que já esta posicionado no título (SE1)
	cQry := "SELECT SL2.L2_MIDCOD, SL1.L1_NUM "
	cQry += CRLF + " FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 "
	cQry += CRLF + " INNER JOIN " + RetSqlName("SL2") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2 "
	cQry += CRLF + " ON (SL2.D_E_L_E_T_ = ' ' AND SL2.L2_FILIAL = SL1.L1_FILIAL AND SL2.L2_NUM = SL1.L1_NUM AND SL2.L2_DOC = SL1.L1_DOC AND SL2.L2_SERIE = SL1.L1_SERIE)"
	cQry += CRLF + " WHERE SL1.D_E_L_E_T_ = ' ' "
	cQry += CRLF + " AND SL1.L1_FILIAL	= '"+SE1->E1_FILIAL+"'"
	cQry += CRLF + " AND SL1.L1_SERIE = '"+SE1->E1_PREFIXO+"'"
	cQry += CRLF + " AND SL1.L1_DOC = '"+SE1->E1_NUM+"'"
	cQry += CRLF + " AND SL1.L1_SERIE = '"+SE1->E1_SERIE+"'"
	cQry += CRLF + " AND SL1.L1_DOC = '"+SE1->E1_NUMNOTA+"'"
	//cQry += CRLF + " AND SL1.L1_SITUA = 'OK'"
	//cQry += CRLF + " AND SL2.L2_MIDCOD <> ''" //somente abastecimentos, ou seja, preenchido o L2_MIDCOD
	cQry += CRLF + " ORDER BY SL1.L1_FILIAL, SL1.L1_NUM"

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYDUP"

	While QRYDUP->(!EOF())

		If !Empty(QRYDUP->L2_MIDCOD) .and. !U_PodeUseAbast(QRYDUP->L2_MIDCOD, QRYDUP->L1_NUM,,@cDodSerAbst,.T.)
			lRet := .T. //possui duplicidade
			//ABASTDUPL - "Abastecimento " + QRYDUP->L2_MIDCOD + " também utilizado em outra venda. " + cDodSerAbst + ". Verifique necessidade de devolução!" + CRLF
			Exit //sai do While...
		EndIf

		QRYDUP->(DbSkip())
	EndDo

	If Select("QRYDUP") > 0
		QRYDUP->(dbCloseArea())
	Endif

Return lRet

/*
Static Function TemDev(cFil,cTit,cPref,cCli,cLojaCli)

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYDEV") > 0
		QRYDEV->(dbCloseArea())
	Endif

	cQry := "SELECT SD1.D1_DOC"
	cQry += CRLF + " FROM "+RetSqlName("SD1")+" SD1"
	cQry += CRLF + " WHERE SD1.D_E_L_E_T_	<> '*'"

	If cFil == Nil
		cQry += CRLF + " AND SD1.D1_FILIAL 	= '"+xFilial("SD1")+"'"
	Else
		cQry += CRLF + " AND SD1.D1_FILIAL 	= '"+cFil+"'"
	Endif

	cQry += CRLF + " AND SD1.D1_TIPO		= 'D'" // Devolução
	cQry += CRLF + " AND SD1.D1_NFORI		= '"+cTit+"'"
	cQry += CRLF + " AND SD1.D1_SERIORI	= '"+cPref+"'"
	cQry += CRLF + " AND SD1.D1_FORNECE	= '"+cCli+"'"
	cQry += CRLF + " AND SD1.D1_LOJA		= '"+cLojaCli+"'"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETE017.txt",cQry)
	TcQuery cQry NEW Alias "QRYDEV"

	If QRYDEV->(!EOF())
		lRet := .T.
	Endif

	If Select("QRYDEV") > 0
		QRYDEV->(dbCloseArea())
	Endif

Return lRet
*/

/******************************/
Static Function CliqueBol(nChk)
/******************************/

	If nChk == 1 // Bol. relacionado

		If lCheckBox5
			lCheckBox7 := .F.
		Endif
	Else
		If lCheckBox7
			lCheckBox5 := .F.
		Endif
	Endif

	oCheckBox5:Refresh()
	oCheckBox7:Refresh()

Return

/*****************************/
Static Function CliqueNf(nChk)
/*****************************/

	If nChk == 1 // NF relacionada

		If lCheckBox6
			lCheckBox8 := .F.
		Endif
	Else
		If lCheckBox8
			lCheckBox6 := .F.
		Endif
	Endif

	oCheckBox6:Refresh()
	oCheckBox8:Refresh()

Return

/*******************************/
Static Function ExecFiltro(nOri)
/*******************************/

	Local nX
	Local lChangeFil := .F.
	Local lOk := .T.

// Consistência da Dt. Referência
	If !Empty(dGet24)

		If dGet24 <> dDataBase // Dt. referência diferente da Data atual

			If dGet24 > dDataBase

				MsgInfo("Parâmetro <Dt. referencia> não pode ser superior a data atual.","Atenção")
				lOk := .F.
			Endif
		Endif
	Else
		MsgInfo("Parâmetro <Dt. referencia> obrigatório.","Atenção")
		lOk := .F.
	Endif

	//verifico se houve mudança dos filtros, para alertar caso clique sem modificar o filtro
	for nX := 1 to len(aDefFilter)
		//campos texto
		if aDefFilter[nX][1] == "cGet4" .OR.; //Filial ?
			aDefFilter[nX][1] == "cGet5" .OR.; //Usuário reps. cliente ?
			aDefFilter[nX][1] == "cGet6" .OR.; //Cliente ?
			aDefFilter[nX][1] == "cGet7" .OR.; //Grupo Cliente ?
			aDefFilter[nX][1] == "cGet8" .OR.; //Filiais Origem ?  ou Segmento Cliente ?
			aDefFilter[nX][1] == "cGet9" .OR.; //Condição de Pagamento ?
			aDefFilter[nX][1] == "cGet10" .OR.; //Forma de Pagamento ?
			aDefFilter[nX][1] == "cGet11" .OR.; //Produto ?
			aDefFilter[nX][1] == "cGet12" .OR.; //Grupo de Produto ?
			aDefFilter[nX][1] == "cGet17" .OR.; //Classe Cliente ?
			aDefFilter[nX][1] == "cGet18" .OR.; //Motivo saque ?
			aDefFilter[nX][1] == "cGet21" .OR.; //Título de ?
			aDefFilter[nX][1] == "cGet22" .OR.; //Título ate ?
			aDefFilter[nX][1] == "cStatusMail" .OR.; //Envio de Email
			aDefFilter[nX][1] == "cGet23"  //Placa ?

			if alltrim(aDefFilter[nX][2]) <> alltrim(&(aDefFilter[nX][1]))
				lChangeFil := .T.
				EXIT
			endif
		endif

		//campos data
		if aDefFilter[nX][1] == "dGet13" .OR.; //Emissão de ?
			aDefFilter[nX][1] == "dGet14" .OR.; //Emissão ate ?
			aDefFilter[nX][1] == "dGet15" .OR.; //Vencimento de ?
			aDefFilter[nX][1] == "dGet16" .OR.; //Vencimento ate ?
			aDefFilter[nX][1] == "dGet19" .OR.; //Dt. p/ fatura de ?
			aDefFilter[nX][1] == "dGet20" //Dt. p/ fatura ate ?

			if aDefFilter[nX][2] <> &(aDefFilter[nX][1])
				lChangeFil := .T.
				EXIT
			endif
		endif
	next nX

	if !lChangeFil
		if !MsgNoYes("Não foi adicionado filtros nos campos da tela. A busca e carregamento dos dados podem demorar. Deseja continuar mesmo assim?","Atenção!")
			lOk := .F.
		endif
	endif

	If nOri == 1 // Botão Aplicar Filtro
		If lOk
			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
			lFiltro := .T.
			oFolderFat:ShowPage(2)
		Endif
	Else // bChange do Folder
		if lOk
			Processa({|lEnd| Filtro(@lEnd)}, "Realizando a consulta...")
		endif
	Endif

Return lOk

Static Function LimpaFiltro(oDlgRef)
	
	Local nX := 0

	for nX := 1 to len(aDefFilter)

		&(aDefFilter[nX][1]) := aDefFilter[nX][2]

	next nX

	oDlgRef:Refresh()

Return

/*****************************/
Static Function RetRpVls(aAux)
/*****************************/

	Local lRet := .F.
	Local nI

	For nI := 1 To Len(aAux)

		If AllTrim(aAux[nI][nPosTipo]) == "RP" .Or. AllTrim(aAux[nI][nPosTipo]) == "VLS"
			lRet := .T.
			Exit
		Endif
	Next

Return lRet

/******************************/
Static Function IfVaziaS(_aAux)
/******************************/

	Local lRet := .F.
	Local nI

	For nI := 1 To Len(_aAux)

		If Empty(_aAux[nI][nPosMotiv])
			lRet := .T.
			Exit
		Endif
	Next

Return lRet

/******************************/
Static Function IfVaziaO(_aAux)
/******************************/

	Local lRet := .F.
	Local nI

	For nI := 1 To Len(_aAux)

		If Empty(_aAux[nI][nPosProdOs])
			lRet := .T.
			Exit
		Endif
	Next

Return lRet

/*****************************************************************/
Static Function OrigFatur(cFil,cPref,cTit,cParc,cTp,cCli,cLojaCli)
/*****************************************************************/

	Local cRet 	:= ""
	Local cQry	:= ""

	cQry := " SELECT DISTINCT FI7.FI7_TIPORI "
	cQry += " FROM "+RetSqlName("FI7")+" FI7 "
	cQry += " WHERE FI7.FI7_PRFDES	= '"+cPref+"'"
	cQry += " AND FI7.FI7_NUMDES	= '"+cTit+"'"
	cQry += " AND FI7.FI7_PARDES	= '"+cParc+"'"
	cQry += " AND FI7.FI7_TIPDES	= '"+cTp+"'"
	cQry += " AND FI7.FI7_CLIDES	= '"+cCli+"'"
	cQry += " AND FI7.FI7_LOJDES	= '"+cLojaCli+"'"
	cQry += " AND FI7.D_E_L_E_T_	= ' '"
	cQry += " AND FI7.FI7_FILDES	= '"+cFil+"'"
	cQry := ChangeQuery(cQry)

	If Select("ORI") > 0
		ORI->(DbCloseArea())
	EndIf

	TcQuery cQry New Alias "ORI"

	If Contar("ORI", "!EOF()") > 0

		ORI->(DbGoTop())

		While ORI->(!EOF())

			If Empty(AllTrim(cRet))
				cRet := ORI->FI7_TIPORI
			Else
				If !(ORI->FI7_TIPORI $ cRet)
					cRet += "/"+ORI->FI7_TIPORI
				EndIf
			EndIf

			ORI->(DbSkip())
		EndDo
	EndIf

	ORI->(DbCloseArea())

Return cRet

/*******************************************************************/
Static Function BuscaFT(cPref,cNum,cParcela,cTipo,cCliente,cLojaCli)
/*******************************************************************/

	//FI7_FILIAL+FI7_PRFORI+FI7_NUMORI+FI7_PARORI+FI7_TIPORI+FI7_CLIORI+FI7_LOJORI
	Local cFT := Posicione("FI7",1,xFilial("FI7")+cPref+cNum+cParcela+cTipo+cCliente+cLojaCli,"FI7_NUMDES")

	//Local cQry	:= ""
//
	//If Select("QRYFT") > 0
	//	QRYFT->(dbCloseArea())
	//EndIf
//
	//cQry := "SELECT FI7_NUMDES"
	//cQry += CRLF + " FROM "+RetSqlName("FI7")+""
	//cQry += CRLF + " WHERE D_E_L_E_T_	<> '*'"
	//cQry += CRLF + " AND FI7_FILIAL	= '"+xFilial("FI7")+"'"
	//cQry += CRLF + " AND FI7_PRFORI	= '"+cPref+"'"
	//cQry += CRLF + " AND FI7_NUMORI	= '"+cNum+"'"
	//cQry += CRLF + " AND FI7_PARORI	= '"+cParcela+"'"
	//cQry += CRLF + " AND FI7_TIPORI	= '"+cTipo+"'"
	//cQry += CRLF + " AND FI7_CLIORI	= '"+cCliente+"'"
	//cQry += CRLF + " AND FI7_LOJORI	= '"+cLojaCli+"'"
//
	//cQry := ChangeQuery(cQry)
//Me//moWrite("c:\temp\TRETE017.txt",cQry)
	//TcQuery cQry NEW Alias "QRYFT"
//
	//If QRYFT->(!EOF())
	//	cFT := QRYFT->FI7_NUMDES
	//EndIf
//
	//If Select("QRYFT") > 0
	//	QRYFT->(dbCloseArea())
	//EndIf

Return cFT

/*
Static Function RetSerVd(cDoc,cSerie,cCliente,cLojaCli)

	Local cSerVd 	:= ""
	Local cQry		:= ""

	If Select("QRYVENDA") > 0
		QRYVENDA->(DbCloseArea())
	Endif

	cQry := "SELECT SF2.F2_SERIE"
	cQry += CRLF + " FROM "+RetSqlName("SF2")+" SF2"
	cQry += CRLF + " WHERE SF2.D_E_L_E_T_	<> '*'"
	cQry += CRLF + " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"
	cQry += CRLF + " AND SF2.F2_DOC		= '"+cDoc+"'"
	cQry += CRLF + " AND SF2.F2_SERIE		= '"+cSerie+"'"
	cQry += CRLF + " AND SF2.F2_CLIENTE	= '"+cCliente+"'"
	cQry += CRLF + " AND SF2.F2_LOJA		= '"+cLojaCli+"'"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYVENDA.txt",cQry)
	TcQuery cQry NEW Alias "QRYVENDA"

	If QRYVENDA->(!EOF())
		cSerVd := QRYVENDA->F2_SERIE
	EndIf

	If Select("QRYVENDA") > 0
		QRYVENDA->(DbCloseArea())
	Endif

Return cSerVd
*/

/***********************************************************/
//SubFunção - LimpMemo
/***********************************************************/
Static Function LimpMemo(_oObjeto,_cInf)

	_cInf := Space(200)
	_oObjeto:Refresh()

Return

/************************************/
Static Function IncTit(nTipo,nRecSE1,lFParc)
/************************************/

	Local lRet			:= .T.
	Local aAreaSE1		:= {} // Gianluka Moraes | 09-08-16 : Informaçoes para gerar o boleto
	Local aBoleto		:= {} // Gianluka Moraes | 09-08-16 : Informaçoes para gerar o boleto

	Local cTit			:= ""
	Local cParcela		:= ""

	Local aFin040 		:= {}
	Local nI

	Local cAuxParc		:= ""
	Local nSldAux		:= 0
	Local nVlrParc		:= 0
	Local nVlrAux		:= 0

	Local cPortador 	:= ""
	Local cAgencia		:= ""
	Local cConta		:= ""

	Local cBlFuncBol
	Local cBlFuncFat

	Default lFParc		:= .F.

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecSE1))
	aAreaSE1 := SE1->( GetArea() )

	cTit := SE1->E1_NUM

	If nTipo == 1 //Vencimento único

		cParcela 	:= Soma1(RetParc(cTit, "REN", SE1->E1_TIPO))

		AAdd(aFin040, {"E1_FILIAL"	, SE1->E1_FILIAL 																,Nil } )
		AAdd(aFin040, {"E1_PREFIXO"	, "REN"          						   					   					,Nil } )
		AAdd(aFin040, {"E1_NUM"		, cTit			 	   															,Nil } )
		AAdd(aFin040, {"E1_PARCELA"	, cParcela								   					   					,Nil } )
		AAdd(aFin040, {"E1_TIPO"	, SE1->E1_TIPO 							   										,Nil } )
		AAdd(aFin040, {"E1_NATUREZ"	, SE1->E1_NATUREZ											   					,Nil } )
		AAdd(aFin040, {"E1_PORTADO"	, SE1->E1_PORTADO						   										,Nil } )
		AAdd(aFin040, {"E1_SITUACA"	, SE1->E1_SITUACA						   					   					,Nil } )
		AAdd(aFin040, {"E1_VENCTO"	, dDtNova																		,Nil } )
		AAdd(aFin040, {"E1_VENCREA"	, DataValida(dDtNova)					   										,Nil } )
		AAdd(aFin040, {"E1_VENCORI"	, DataValida(dDtNova)					   										,Nil } )
		AAdd(aFin040, {"E1_EMISSAO"	, dDataBase								   										,Nil } )
		AAdd(aFin040, {"E1_EMIS1"	, dDataBase								   										,Nil } )
		AAdd(aFin040, {"E1_CLIENTE"	, SE1->E1_CLIENTE						   					   					,Nil } )
		AAdd(aFin040, {"E1_LOJA"	, SE1->E1_LOJA							   										,Nil } )
		aAdd(aFin040, {"E1_NOMCLI" 	, SE1->E1_NOMCLI																,NIL } )
		AAdd(aFin040, {"E1_MOEDA"	, SE1->E1_MOEDA							   										,Nil } )
		AAdd(aFin040, {"E1_VALOR"	, nSldOrig/*nSldNovo*/					   										,Nil } )
		AAdd(aFin040, {"E1_SALDO"	, nSldOrig/*nSldNovo*/					   										,Nil } )
		AAdd(aFin040, {"E1_VLCRUZ"	, xMoeda(nSldOrig/*nSldNovo*/,SE1->E1_MOEDA,1)									,Nil } )
		AAdd(aFin040, {"E1_STATUS"	, SE1->E1_STATUS						   										,Nil } )
		//AAdd(aFin040, {"E1_ORIGEM" 	, "RFATE001"																	,Nil } )
		AAdd(aFin040, {"E1_FATURA" 	, SE1->E1_FATURA																,Nil } )
		AAdd(aFin040, {"E1_CREDIT" 	, SE1->E1_CREDIT																,Nil } )
		AAdd(aFin040, {"E1_DEBITO" 	, SE1->E1_DEBITO																,Nil } )
		AAdd(aFin040, {"E1_CCC"		, SE1->E1_CCC							   										,Nil } )
		AAdd(aFin040, {"E1_ITEMC"	, SE1->E1_ITEMC							   										,Nil } )
		AAdd(aFin040, {"E1_CLVLCR"	, SE1->E1_CLVLCR						   										,Nil } )
		AAdd(aFin040, {"E1_CCD"		, SE1->E1_CCD							   										,Nil } )
		AAdd(aFin040, {"E1_ITEMD"	, SE1->E1_ITEMD							   										,Nil } )
		AAdd(aFin040, {"E1_CLVLDB"	, SE1->E1_CLVLDB						   										,Nil } )
		AAdd(aFin040, {"E1_AGEDEP"	, SE1->E1_AGEDEP						   										,Nil } )
		AAdd(aFin040, {"E1_CONTA"	, SE1->E1_CONTA							   										,Nil } )
		AAdd(aFin040, {"E1_XPLACA"	, SE1->E1_XPLACA						   										,Nil } )
		AAdd(aFin040, {"E1_XCOND"	, SE1->E1_XCOND							   										,Nil } )
		if SE1->(FIELDPOS("E1_XUSRFAT"))>0
			AAdd(aFin040, {"E1_XUSRFAT"	, SE1->E1_XUSRFAT						   										,Nil } )
		endif
		AAdd(aFin040, {"E1_VEND1"	, SE1->E1_VEND1							   										,Nil } )
		AAdd(aFin040, {"E1_VEND2"	, SE1->E1_VEND2							   										,Nil } )
		AAdd(aFin040, {"E1_VEND3"	, SE1->E1_VEND3							   										,Nil } )
		AAdd(aFin040, {"E1_VEND4"	, SE1->E1_VEND4							   										,Nil } )
		AAdd(aFin040, {"E1_VEND5"	, SE1->E1_VEND5							   										,Nil } )
		AAdd(aFin040, {"E1_COMIS1"	, SE1->E1_COMIS1						   										,Nil } )
		AAdd(aFin040, {"E1_COMIS2"	, SE1->E1_COMIS2						   										,Nil } )
		AAdd(aFin040, {"E1_COMIS3"	, SE1->E1_COMIS3						   										,Nil } )
		AAdd(aFin040, {"E1_COMIS4"	, SE1->E1_COMIS4						   										,Nil } )
		AAdd(aFin040, {"E1_COMIS5"	, SE1->E1_COMIS2						   										,Nil } )
		AAdd(aFin040, {"E1_BASCOM1"	, SE1->E1_BASCOM1						   										,Nil } )
		AAdd(aFin040, {"E1_BASCOM2"	, SE1->E1_BASCOM2						   										,Nil } )
		AAdd(aFin040, {"E1_BASCOM3"	, SE1->E1_BASCOM3						   										,Nil } )
		AAdd(aFin040, {"E1_BASCOM4"	, SE1->E1_BASCOM4						   										,Nil } )
		AAdd(aFin040, {"E1_BASCOM5"	, SE1->E1_BASCOM5						   										,Nil } )
		AAdd(aFin040, {"E1_HIST" 	, "RENEG. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""   			,Nil } ) //AAdd(aFin040, {"E1_HIST"	, "RENEG. TIT "+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PARCELA)+""			,Nil } )
		AAdd(aFin040, {"E1_ACRESC"	, IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0)							,Nil } )
		AAdd(aFin040, {"E1_SDACRES"	, IIF(nSldNovo - nSldOrig > 0,nSldNovo - nSldOrig,0)							,Nil } )
		AAdd(aFin040, {"E1_DECRESC"	, IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0)							,Nil } )
		AAdd(aFin040, {"E1_SDDECRE"	, IIF(nSldOrig - nSldNovo > 0,nSldOrig - nSldNovo,0)							,Nil } )

		MSExecAuto({|x,y| FINA040(x,y)},aFin040,3)

		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
			lRet := .F.
		Else
			If SE1->( DbSeek(SE1->E1_FILIAL+"REN"+cTit+cParcela+SE1->E1_TIPO) )
				If .F. //MSGYESNO("Deseja enviar o boleto por email ?")
					aBoleto := {}
					AAdd(aBoleto,SE1->E1_PREFIXO) 						//[1]Prefixo - De
					AAdd(aBoleto,SE1->E1_PREFIXO) 						//[2]Prefixo - Ate
					AAdd(aBoleto,SE1->E1_NUM) 							//[3]Numero - De
					AAdd(aBoleto,SE1->E1_NUM) 							//[4]Numero - Ate
					AAdd(aBoleto,SE1->E1_PARCELA) 						//[5]Parcela - De
					AAdd(aBoleto,SE1->E1_PARCELA) 						//[6]Parcela - Ate
					AAdd(aBoleto,SE1->E1_PORTADO) 						//[7]Portador - De
					AAdd(aBoleto,SE1->E1_PORTADO) 						//[8]Portador - Ate
					AAdd(aBoleto,SE1->E1_CLIENTE) 						//[9]Cliente - De
					AAdd(aBoleto,SE1->E1_CLIENTE) 						//[10]Cliente - Ate
					AAdd(aBoleto,SE1->E1_LOJA) 							//[11]Loja - De
					AAdd(aBoleto,SE1->E1_LOJA) 							//[12]Loja - Ate
					AAdd(aBoleto,SE1->E1_EMISSAO) 						//[13]Emissão - De
					AAdd(aBoleto,SE1->E1_EMISSAO) 						//[14]Emissão - Ate
					AAdd(aBoleto,SE1->E1_VENCREA)						//[15]Vencimento - De
					AAdd(aBoleto,SE1->E1_VENCREA)						//[16]Vencimento - Ate
					AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 		//[17]Nr. Bordero - De
					AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) //[18]Nr. Bordero - Ate
					AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 			//[19]Carga - De
					AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 	//[20]Carga - Ate
					AAdd(aBoleto,"") 									//[21]Mensagem 1
					AAdd(aBoleto,"") 									//[22]Mensagem 2
					cBlFuncBol := "U_"+cFImpBol+"(aBoleto,,.T.,,.F.)"
					&cBlFuncBol
				EndIF
				RestArea(aAreaSE1)
			EndIf
		EndIf

	ElseIf nTipo == 2 //Parcelamento

		If lFParc
			cParcela := RetParc(cTit, "FAT", 'FT')
		Else
			cParcela := RetParc(cTit, "REN", SE1->E1_TIPO)
		EndIf

		//Selecionando Cliente + Loja e Portador
		If lFParc
			SE1->(DbGoTo(nRecSE1))
			dbSelectArea("U88")
			U88->(dbSetOrder(1))
			If U88->(dbSeek(xFilial("U88")+"FT"+Space(4)+SE1->E1_CLIENTE+SE1->E1_LOJA))
				cPortador 	:= U88->U88_BANCOC
				cAgencia	:= U88->U88_AGC
				cConta		:= U88->U88_CONTAC
			Endif
		endif

		For nI := 1 To Len(aParcelas)

			If lRet

				aFin040	:= {}
				SE1->(DbGoTo(nRecSE1))

				If nI == 1
					cAuxParc := Soma1(cParcela)
				Else
					cAuxParc := Soma1(cAuxParc)
				Endif

				AAdd(aFin040, {"E1_FILIAL"	, SE1->E1_FILIAL											   					,Nil } )
				If lFParc
					AAdd(aFin040, {"E1_PREFIXO"	, "FAT"        						   					   					,Nil } )
				Else
					AAdd(aFin040, {"E1_PREFIXO"	, "REN"        						   					   					,Nil } )
				EndIf
				AAdd(aFin040, {"E1_NUM"		, cTit			 	   															,Nil } )
				AAdd(aFin040, {"E1_PARCELA"	, cAuxParc								   					   					,Nil } )
				If lFParc
					AAdd(aFin040, {"E1_TIPO"	, 'FT'	 							   										,Nil } )
				Else
					AAdd(aFin040, {"E1_TIPO"	, SE1->E1_TIPO						   										,Nil } )
				EndIf
				AAdd(aFin040, {"E1_NATUREZ"	, SE1->E1_NATUREZ											   					,Nil } )
				If lFParc
					AAdd(aFin040, {"E1_PORTADO"	, cPortador						   											,Nil } )
					AAdd(aFin040, {"E1_AGEDEP"	, cAgencia						   											,Nil } )
					AAdd(aFin040, {"E1_CONTA"	, cConta							   										,Nil } )
				Else
					AAdd(aFin040, {"E1_PORTADO"	, SE1->E1_PORTADO						   									,Nil } )
					AAdd(aFin040, {"E1_AGEDEP"	, SE1->E1_AGEDEP						   									,Nil } )
					AAdd(aFin040, {"E1_CONTA"	, SE1->E1_CONTA							   									,Nil } )
				EndIf
				AAdd(aFin040, {"E1_SITUACA"	, SE1->E1_SITUACA						   					   					,Nil } )
				AAdd(aFin040, {"E1_VENCTO"	, aParcelas[nI][1]																,Nil } )
				AAdd(aFin040, {"E1_VENCREA"	, DataValida(aParcelas[nI][1])			   										,Nil } )
				AAdd(aFin040, {"E1_VENCORI"	, DataValida(aParcelas[nI][1])			   										,Nil } )
				AAdd(aFin040, {"E1_EMISSAO"	, dDataBase								   										,Nil } )
				AAdd(aFin040, {"E1_EMIS1"	, dDataBase								   										,Nil } )
				AAdd(aFin040, {"E1_CLIENTE"	, SE1->E1_CLIENTE						   					   					,Nil } )
				AAdd(aFin040, {"E1_LOJA"	, SE1->E1_LOJA							   										,Nil } )
				aAdd(aFin040, {"E1_NOMCLI" 	, SE1->E1_NOMCLI																,NIL } )
				AAdd(aFin040, {"E1_MOEDA"	, SE1->E1_MOEDA							   										,Nil } )
				If lFParc
					AAdd(aFin040, {"E1_VALOR"	, aParcelas[nI][2]					   										,Nil } )
					AAdd(aFin040, {"E1_SALDO"	, aParcelas[nI][2]					   										,Nil } )
					AAdd(aFin040, {"E1_VLCRUZ"	, xMoeda(aParcelas[nI][2],SE1->E1_MOEDA,1)									,Nil } )
				Else
					AAdd(aFin040, {"E1_VALOR"	, aParcOrig[nI][2]/*aParcelas[nI][2]*/	   									,Nil } )
					AAdd(aFin040, {"E1_SALDO"	, aParcOrig[nI][2]/*aParcelas[nI][2]*/	   									,Nil } )
					AAdd(aFin040, {"E1_VLCRUZ"	, xMoeda(aParcOrig[nI][2]/*aParcelas[nI][2]*/,SE1->E1_MOEDA,1)				,Nil } )
				EndIf
				AAdd(aFin040, {"E1_STATUS"	, SE1->E1_STATUS						   										,Nil } )
				AAdd(aFin040, {"E1_OCORREN"	, SE1->E1_OCORREN						   										,Nil } )
				//AAdd(aFin040, {"E1_ORIGEM" 	, "RFATE001"																	,Nil } )
				If lFParc
					AAdd(aFin040, {"E1_FATURA" 	, "NOTFAT"																	,Nil } )
				Else
					AAdd(aFin040, {"E1_FATURA" 	, SE1->E1_FATURA															,Nil } )
				EndIf
				AAdd(aFin040, {"E1_CREDIT" 	, SE1->E1_CREDIT																,Nil } )
				AAdd(aFin040, {"E1_DEBITO" 	, SE1->E1_DEBITO																,Nil } )
				AAdd(aFin040, {"E1_CCC"		, SE1->E1_CCC							   										,Nil } )
				AAdd(aFin040, {"E1_ITEMC"	, SE1->E1_ITEMC							   										,Nil } )
				AAdd(aFin040, {"E1_CLVLCR"	, SE1->E1_CLVLCR						   										,Nil } )
				AAdd(aFin040, {"E1_CCD"		, SE1->E1_CCD							   										,Nil } )
				AAdd(aFin040, {"E1_ITEMD"	, SE1->E1_ITEMD							   										,Nil } )
				AAdd(aFin040, {"E1_CLVLDB"	, SE1->E1_CLVLDB						   										,Nil } )
				AAdd(aFin040, {"E1_XPLACA"	, SE1->E1_XPLACA						   										,Nil } )
				AAdd(aFin040, {"E1_XCOND"	, SE1->E1_XCOND							   										,Nil } )
				if SE1->(FIELDPOS("E1_XUSRFAT"))>0
					AAdd(aFin040, {"E1_XUSRFAT"	, SE1->E1_XUSRFAT						   										,Nil } )
				endif
				AAdd(aFin040, {"E1_VEND1"	, SE1->E1_VEND1							   										,Nil } )
				AAdd(aFin040, {"E1_VEND2"	, SE1->E1_VEND2							   										,Nil } )
				AAdd(aFin040, {"E1_VEND3"	, SE1->E1_VEND3							   										,Nil } )
				AAdd(aFin040, {"E1_VEND4"	, SE1->E1_VEND4							   										,Nil } )
				AAdd(aFin040, {"E1_VEND5"	, SE1->E1_VEND5							   										,Nil } )
				AAdd(aFin040, {"E1_COMIS1"	, SE1->E1_COMIS1						   										,Nil } )
				AAdd(aFin040, {"E1_COMIS2"	, SE1->E1_COMIS2						   										,Nil } )
				AAdd(aFin040, {"E1_COMIS3"	, SE1->E1_COMIS3						   										,Nil } )
				AAdd(aFin040, {"E1_COMIS4"	, SE1->E1_COMIS4						   										,Nil } )
				AAdd(aFin040, {"E1_COMIS5"	, SE1->E1_COMIS2						   										,Nil } )
				If lFParc
					AAdd(aFin040, {"E1_HIST" 	, "PARCE. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""	   		,Nil } )
					AAdd(aFin040, {"E1_BASCOM1"	, aParcelas[nI][2]						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM2"	, aParcelas[nI][2]						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM3"	, aParcelas[nI][2]						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM4"	, aParcelas[nI][2]						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM5"	, aParcelas[nI][2]						   									,Nil } )
				Else
					AAdd(aFin040, {"E1_BASCOM1"	, SE1->E1_BASCOM1						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM2"	, SE1->E1_BASCOM2						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM3"	, SE1->E1_BASCOM3						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM4"	, SE1->E1_BASCOM4						   									,Nil } )
					AAdd(aFin040, {"E1_BASCOM5"	, SE1->E1_BASCOM5						   									,Nil } )
					AAdd(aFin040, {"E1_HIST" 	, "RENEG. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""	   		,Nil } ) //AAdd(aFin040, {"E1_HIST"	, "RENEG. TIT "+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PARCELA)+""			,Nil } )
					AAdd(aFin040, {"E1_ACRESC"	, IIF(aParcelas[nI][2] - aParcOrig[nI][2] > 0,aParcelas[nI][2] - aParcOrig[nI][2],0)	,Nil } )
					AAdd(aFin040, {"E1_SDACRES"	, IIF(aParcelas[nI][2] - aParcOrig[nI][2] > 0,aParcelas[nI][2] - aParcOrig[nI][2],0)	,Nil } )
					AAdd(aFin040, {"E1_DECRESC"	, IIF(aParcOrig[nI][2] - aParcelas[nI][2] > 0,aParcOrig[nI][2] - aParcelas[nI][2],0)	,Nil } )
					AAdd(aFin040, {"E1_SDDECRE"	, IIF(aParcOrig[nI][2] - aParcelas[nI][2] > 0,aParcOrig[nI][2] - aParcelas[nI][2],0)	,Nil } )
				EndIf

				MSExecAuto({|x,y| FINA040(x,y)},aFin040,3)

				If lMsErroAuto
					MostraErro()
					DisarmTransaction()
					lRet := .F.
				Else
					//imprime fatura
					if lPDFFat
						cBlFuncFat := "U_"+cFImpFat+"(,cFilAnt,{{cTit,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_PREFIXO,SE1->E1_PARCELA,SE1->E1_TIPO}},.T.,,,,cGet25)"
						&cBlFuncFat
					endif

					//Verifica se há geração de Boleto Bancário
					U88->(dbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
					If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+SE1->E1_CLIENTE+SE1->E1_LOJA))
						If U88->U88_TPCOBR == "B" //Boleto Bancário
							//Gerar Boleto
							ImpBol(,5,cFilAnt,SE1->E1_NUM,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_PREFIXO,SE1->E1_PARCELA)
						Endif
					Endif
				EndIf
			Endif
		Next nI

	Else //Parcelamento flexível

		cParcela := RetParc(cTit, "REN", SE1->E1_TIPO)

		For nI := 1 To Len(oGet1:aCols)

			If oGet1:aCols[nI,Len(oGet1:aHeader)+1] == .F. //Não estiver deletado

				If !Empty(oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})])

					If lRet

						aFin040	:= {}
						SE1->(DbGoTo(nRecSE1))

						nSldAux += oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})]

						If nI == 1
							cAuxParc := Soma1(cParcela)
						Else
							cAuxParc := Soma1(cAuxParc)
						Endif

						AAdd(aFin040, {"E1_FILIAL"	, SE1->E1_FILIAL											   					,Nil } )
						AAdd(aFin040, {"E1_PREFIXO"	, "REN"          						   					   					,Nil } )
						AAdd(aFin040, {"E1_NUM"		, cTit			 	   															,Nil } )
						AAdd(aFin040, {"E1_PARCELA"	, cAuxParc								   					   					,Nil } )
						AAdd(aFin040, {"E1_TIPO"	, SE1->E1_TIPO 							   										,Nil } )
						AAdd(aFin040, {"E1_NATUREZ"	, SE1->E1_NATUREZ											   					,Nil } )
						AAdd(aFin040, {"E1_PORTADO"	, SE1->E1_PORTADO						   										,Nil } )
						AAdd(aFin040, {"E1_SITUACA"	, SE1->E1_SITUACA						   					   					,Nil } )
						AAdd(aFin040, {"E1_VENCTO"	, oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="DTVENC"})]			,Nil } )
						AAdd(aFin040, {"E1_VENCREA"	, DataValida(oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="DTVENC"})]),Nil } )
						AAdd(aFin040, {"E1_VENCORI"	, DataValida(oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="DTVENC"})]),Nil } )
						AAdd(aFin040, {"E1_EMISSAO"	, dDataBase								   										,Nil } )
						AAdd(aFin040, {"E1_EMIS1"	, dDataBase								   										,Nil } )
						AAdd(aFin040, {"E1_CLIENTE"	, SE1->E1_CLIENTE						   					   					,Nil } )
						AAdd(aFin040, {"E1_LOJA"	, SE1->E1_LOJA							   										,Nil } )
						aAdd(aFin040, {"E1_NOMCLI" 	, SE1->E1_NOMCLI																,NIL } )
						AAdd(aFin040, {"E1_MOEDA"	, SE1->E1_MOEDA							   										,Nil } )
						AAdd(aFin040, {"E1_VLCRUZ"	, xMoeda(oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="VALOR"})],SE1->E1_MOEDA,1),Nil } )
						AAdd(aFin040, {"E1_STATUS"	, SE1->E1_STATUS						   										,Nil } )
						AAdd(aFin040, {"E1_OCORREN"	, SE1->E1_OCORREN						   										,Nil } )
						//AAdd(aFin040, {"E1_ORIGEM" 	, "RFATE001"																	,Nil } )
						AAdd(aFin040, {"E1_FATURA" 	, SE1->E1_FATURA																,Nil } )
						AAdd(aFin040, {"E1_CREDIT" 	, SE1->E1_CREDIT																,Nil } )
						AAdd(aFin040, {"E1_DEBITO" 	, SE1->E1_DEBITO																,Nil } )
						AAdd(aFin040, {"E1_CCC"		, SE1->E1_CCC							   										,Nil } )
						AAdd(aFin040, {"E1_ITEMC"	, SE1->E1_ITEMC							   										,Nil } )
						AAdd(aFin040, {"E1_CLVLCR"	, SE1->E1_CLVLCR						   										,Nil } )
						AAdd(aFin040, {"E1_CCD"		, SE1->E1_CCD							   										,Nil } )
						AAdd(aFin040, {"E1_ITEMD"	, SE1->E1_ITEMD							   										,Nil } )
						AAdd(aFin040, {"E1_CLVLDB"	, SE1->E1_CLVLDB						   										,Nil } )
						AAdd(aFin040, {"E1_AGEDEP"	, SE1->E1_AGEDEP						   										,Nil } )
						AAdd(aFin040, {"E1_CONTA"	, SE1->E1_CONTA							   										,Nil } )
						AAdd(aFin040, {"E1_XPLACA"	, SE1->E1_XPLACA						   										,Nil } )
						AAdd(aFin040, {"E1_XCOND"	, SE1->E1_XCOND							   										,Nil } )
						if SE1->(FIELDPOS("E1_XUSRFAT"))>0
							AAdd(aFin040, {"E1_XUSRFAT"	, SE1->E1_XUSRFAT						   										,Nil } )
						endif
						AAdd(aFin040, {"E1_VEND1"	, SE1->E1_VEND1							   										,Nil } )
						AAdd(aFin040, {"E1_VEND2"	, SE1->E1_VEND2							   										,Nil } )
						AAdd(aFin040, {"E1_VEND3"	, SE1->E1_VEND3							   										,Nil } )
						AAdd(aFin040, {"E1_VEND4"	, SE1->E1_VEND4							   										,Nil } )
						AAdd(aFin040, {"E1_VEND5"	, SE1->E1_VEND5							   										,Nil } )
						AAdd(aFin040, {"E1_COMIS1"	, SE1->E1_COMIS1						   										,Nil } )
						AAdd(aFin040, {"E1_COMIS2"	, SE1->E1_COMIS2						   										,Nil } )
						AAdd(aFin040, {"E1_COMIS3"	, SE1->E1_COMIS3						   										,Nil } )
						AAdd(aFin040, {"E1_COMIS4"	, SE1->E1_COMIS4						   										,Nil } )
						AAdd(aFin040, {"E1_COMIS5"	, SE1->E1_COMIS2						   										,Nil } )
						AAdd(aFin040, {"E1_BASCOM1"	, SE1->E1_BASCOM1						   										,Nil } )
						AAdd(aFin040, {"E1_BASCOM2"	, SE1->E1_BASCOM2						   										,Nil } )
						AAdd(aFin040, {"E1_BASCOM3"	, SE1->E1_BASCOM3						   										,Nil } )
						AAdd(aFin040, {"E1_BASCOM4"	, SE1->E1_BASCOM4						   										,Nil } )
						AAdd(aFin040, {"E1_BASCOM5"	, SE1->E1_BASCOM5						   										,Nil } )
						AAdd(aFin040, {"E1_HIST" 	, "RENEG. "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA+""	   			,Nil } )

						If nI == Len(oGet1:aCols) //última parcela

							//Acrescenta acréscimo ou decréscimo
							nVlrParc := oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})]

							If nSldAux - nSldOrig > 0 //Acréscimo
								nVlrAux := nVlrParc - (nSldAux - nSldOrig)
							ElseIf nSldOrig - nSldAux > 0 //Decréscimo
								nVlrAux := nVlrParc + (nSldOrig - nSldAux)
							Endif

							If nVlrAux > 0

								AAdd(aFin040, {"E1_VALOR"	, nVlrAux			,Nil } )
								AAdd(aFin040, {"E1_SALDO"	, nVlrAux			,Nil } )

								AAdd(aFin040, {"E1_ACRESC"	, IIF(nSldAux - nSldOrig > 0,nSldAux - nSldOrig,0)								,Nil } )
								AAdd(aFin040, {"E1_SDACRES"	, IIF(nSldAux - nSldOrig > 0,nSldAux - nSldOrig,0)								,Nil } )
								AAdd(aFin040, {"E1_DECRESC"	, IIF(nSldOrig - nSldAux > 0,nSldOrig - nSldAux,0)								,Nil } )
								AAdd(aFin040, {"E1_SDDECRE"	, IIF(nSldOrig - nSldAux > 0,nSldOrig - nSldAux,0)								,Nil } )
							Else
								AAdd(aFin040, {"E1_VALOR"	, nVlrParc			,Nil } )
								AAdd(aFin040, {"E1_SALDO"	, nVlrParc			,Nil } )
							Endif
						Else
							AAdd(aFin040, {"E1_VALOR"	, oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})]			,Nil } )
							AAdd(aFin040, {"E1_SALDO"	, oGet1:aCols[nI][aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "VALOR"})]			,Nil } )
						Endif

						MSExecAuto({|x,y| FINA040(x,y)},aFin040,3)

						If lMsErroAuto
							MostraErro()
							DisarmTransaction()
							lRet := .F.
						EndIf
					Endif
				Endif
			Endif
		Next nI
	Endif

Return lRet

/********************************/
Static Function BaixaTit(nRecSE1)
/********************************/

	Local lRet			:= .T.
	Local aTit			:= {}
	Local cBkpFunNam := FunName()
	Local nVlrAcess := 0

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecSE1))

	nVlrAcess := U_UFValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1,SE1->E1_TXMOEDA)

	lMsErroAuto := .F.

	AAdd(aTit, {"E1_PREFIXO"	,SE1->E1_PREFIXO					,Nil})
	AAdd(aTit, {"E1_NUM"		,SE1->E1_NUM						,Nil})
	AAdd(aTit, {"E1_PARCELA"	,SE1->E1_PARCELA					,Nil})
	AAdd(aTit, {"E1_TIPO"		,SE1->E1_TIPO						,Nil})
	AAdd(aTit, {"E1_CLIENTE"	,SE1->E1_CLIENTE					,Nil})
	AAdd(aTit, {"E1_LOJA"		,SE1->E1_LOJA						,Nil})
	AAdd(aTit, {"AUTDTBAIXA"	,dDataBase							,Nil})
	AAdd(aTit, {"AUTMOTBX"		,"REN"								,Nil})
	AAdd(aTit, {"AUTDTCREDITO"	,dDataBase							,Nil})
	AAdd(aTit, {"AUTHIST"		,"BAIXA POR RENEGOCIACAO"			,Nil})
	AAdd(aTit, {"AUTVALREC"		,SE1->E1_SALDO	+ SE1->E1_SDACRES - SE1->E1_SDDECRE + nVlrAcess	,Nil})
	AAdd(aTit, {"AUTVLRPG"     	,0              					,Nil})
	AAdd(aTit, {"AUTJUROS"     	,0    			   					,Nil})
	AAdd(aTit, {"AUTMULTA"     	,0    			   					,Nil})
	AAdd(aTit, {"AUTDESCONT"   	,0			       					,Nil})
	AAdd(aTit, {"AUTBANCO"		,SE1->E1_PORTADO					,Nil})
	AAdd(aTit, {"AUTAGENCIA"	,SE1->E1_AGEDEP						,Nil})
	AAdd(aTit, {"AUTCONTA"		,SE1->E1_CONTA						,Nil})

	SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)
	MsExecAuto({|x,y| FINA070(x,y)},aTit,3)
	SetFunName(cBkpFunNam)

	If lMsErroAuto
		MostraErro()
		DisarmTransaction()
		lRet := .F.
	EndIf

Return lRet

Static Function RetParc(_cTit, _cPref, _cTipo)

	Local nTamParc := TamSX3("E1_PARCELA")[1]
	Local cParc := ""
	Local cQry	:= ""
	Default _cPref := ""

	If Select("QRYPARC") > 0
		QRYPARC->(dbCloseArea())
	Endif

	cQry := "SELECT MAX(REPLICATE('0',"+cValToChar(nTamParc)+" - LEN(RTRIM(E1_PARCELA))) + E1_PARCELA) AS PARC"
	cQry += " FROM "+RetSqlName("SE1")+""
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND E1_FILIAL		= '"+xFilial("SE1")+"'"
	cQry += " AND E1_PREFIXO	= '"+_cPref+"'"
	cQry += " AND E1_NUM		= '"+_cTit+"'"
	cQry += " AND E1_TIPO		= '"+_cTipo+"'"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE001_j.txt",cQry)
	TcQuery cQry NEW Alias "QRYPARC"

	If QRYPARC->(!EOF())
		cParc := StrZero(Val(QRYPARC->PARC),nTamParc)
	Else
		cParc := StrZero(1,nTamParc) //"001"
	Endif

	If Select("QRYPARC") > 0
		QRYPARC->(dbCloseArea())
	Endif

Return cParc

/***************************************/
// considera que esta posicionado no título: SE1
Static Function ValidFin()
/***************************************/
	Local lRet :=  .T.
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo

	// verifico se o E1_LA está diferente de vazio, se o conteudo for igual a "S"
	If lVldLA .AND. !Empty(SE1->E1_LA) .And. AllTrim(SE1->E1_LA) == "S"
		MsgStop("O Título <"+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PREFIXO)+"> se encontra contabilizado";
			+ " quanto ao Financerio (E1_LA), operação não permitida. Favor verificar com o depto. contábil ";
			+ "o estorno desta contabilização.","Atenção")
		Return .F.
	EndIf

	//valida a data do movimento financeiro
	If !DtMovFin(SE1->E1_EMISSAO,.T.)
		Return .F.
	EndIf

Return lRet

//Ajusta o valor pelo campo Acrescimo ou Decrescimo
Static Function AjustaValor(nAcresc, nDecresc)

	Local aFin040 := {}
	Local lRet := .T.
	Local nDeci := TamSX3("E1_ACRESC")[2]
	Local cBkpOrigem := ""

	nAcresc := Round(nAcresc, nDeci)
	nDecresc := Round(nDecresc, nDeci)

	//confiro se o valor ja está ok, então nao preciso mudar
	if SE1->E1_ACRESC == nAcresc .AND. SE1->E1_DECRESC == nDecresc
		Return .T.
	endif

	//Montando array para execauto
	AADD(aFin040, {"E1_FILIAL"	,SE1->E1_FILIAL		,Nil } )
	AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO	,Nil } )
	AADD(aFin040, {"E1_NUM"		,SE1->E1_NUM		,Nil } )
	AADD(aFin040, {"E1_PARCELA"	,SE1->E1_PARCELA  	,Nil } )
	AADD(aFin040, {"E1_TIPO"	,SE1->E1_TIPO	   	,Nil } )
	AADD(aFin040, {"E1_CLIENTE"	,SE1->E1_CLIENTE	,Nil } )
	AADD(aFin040, {"E1_LOJA"	,SE1->E1_LOJA		,Nil } )

	AADD(aFin040, {"E1_ACRESC"	,nAcresc	,Nil } )
	AADD(aFin040, {"E1_SDACRES"	,nAcresc	,Nil } )
	AADD(aFin040, {"E1_DECRESC"	,nDecresc	,Nil } )
	AADD(aFin040, {"E1_SDDECRE"	,nDecresc	,Nil } )

	lMsErroAuto := .F. // variavel interna da rotina automatica
	lMsHelpAuto := .F.

	cBkpOrigem := SE1->E1_ORIGEM

	If  Alltrim(SE1->E1_ORIGEM) == "LOJA701" .And. SE1->E1_TIPO $ 'CC |CD |PX |PD '
		//TITPGPIXCART - O título não pode ser alterado pois foi originado pela rotina de Venda Assistida e pago com PIX ou cartões de débito e crédito
		//apaga a origem para ser possível alteração/exclusão do titulo
		RecLock("SE1",.F.)
		SE1->E1_ORIGEM := ""
		SE1->(MsUnlock())
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Chama a funcao de gravacao automatica do FINA040                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MSExecAuto({|x,y| FINA040(x,y)},aFin040, 4)

	if lMsErroAuto
		MostraErro()
		lRet := .F.
	endif
	
	//volta a origem 
	RecLock("SE1",.F.)
		SE1->E1_ORIGEM := cBkpOrigem
	SE1->(MsUnlock())

Return lRet

//Função para ajuste de faturas de cartão que ficaram com o E1_VLRREAL zerado.
User Function AJU017_1()

	Local cQry
	Local nVlrBrt := 0

	If Select("QRYFAT") > 0
		QRYFAT->(DbCloseArea())
	EndIf
	If Select("QRYSE1") > 0
		QRYSE1->(DbCloseArea())
	EndIf

	cQry := " SELECT R_E_C_N_O_, E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_VALOR, E1_VLRREAL, E1_NUMLIQ "
	cQry += " FROM "+RetSqlName("SE1")+"  "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += " AND E1_TIPO = 'FT' "
	cQry += " AND E1_EMISSAO > '20210501' "
	cQry += " AND E1_VLRREAL <= 0 "
	cQry += " AND E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO IN ( "
	cQry += " 	SELECT DISTINCT FI7_FILDES + FI7_PRFDES + FI7_NUMDES + FI7_PARDES + FI7_TIPDES "
	cQry += " 	FROM "+RetSqlName("FI7")+"  "
	cQry += " 	WHERE D_E_L_E_T_ = ' ' "
	cQry += " 	AND FI7_TIPDES = 'FT' "
	cQry += " 	AND FI7_TIPORI IN ('CC', 'CD') "
	cQry += " ) "

	cQry := ChangeQuery(cQry)

	TcQuery cQry NEW Alias "QRYFAT"

	While QRYFAT->(!Eof())

		nVlrBrt := 0

		cQry := " SELECT SUM(E1_VLRREAL) E1_VLRREAL, SUM(E1_VALOR) E1_VALOR "
		cQry += " FROM "+RetSqlName("SE1")+" SE1 "
		cQry += " INNER JOIN "+RetSqlName("FI7")+" FI7 ON ( "
		cQry += " FI7.D_E_L_E_T_ = ' ' AND FI7.FI7_FILIAL = SE1.E1_FILIAL "
		cQry += " AND FI7.FI7_PRFORI = SE1.E1_PREFIXO "
		cQry += " AND FI7.FI7_NUMORI = SE1.E1_NUM "
		cQry += " AND FI7.FI7_PARORI = SE1.E1_PARCELA "
		cQry += " AND FI7.FI7_TIPORI = SE1.E1_TIPO "
		cQry += " AND FI7.FI7_CLIORI = SE1.E1_CLIENTE "
		cQry += " AND FI7.FI7_LOJORI = SE1.E1_LOJA "
		cQry += " AND FI7_FILDES = '"+QRYFAT->E1_FILIAL+"' "
		cQry += " AND FI7_PRFDES = '"+QRYFAT->E1_PREFIXO+"' "
		cQry += " AND FI7_NUMDES = '"+QRYFAT->E1_NUM+"' "
		cQry += " AND FI7_PARDES = '"+QRYFAT->E1_PARCELA+"' "
		cQry += " AND FI7_TIPDES = '"+QRYFAT->E1_TIPO+" ' "
		cQry += " )  "
		cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYSE1"

		If QRYSE1->E1_VLRREAL > 0 .AND. QRYSE1->E1_VLRREAL >= QRYSE1->E1_VALOR

			SE1->(DbGoTo(QRYFAT->R_E_C_N_O_ ))
			RecLock("SE1", .F.)
			SE1->E1_VLRREAL := QRYSE1->E1_VLRREAL
			SE1->(MsUnLock())

		endif

		QRYSE1->(DbCloseArea())


		QRYFAT->(DbSkip())
	enddo

	QRYFAT->(DbCloseArea())

Return


Static Function EnvEmailCli()

	Local nI, nQtdFat
	Local nCont		:= 0
	Local lEnvOk	:= .F.
	Local cCli
	Local cLojaCli
	Local aFatura	:= {}
	Local aAuxFat	:= {}

	For nI := 1 To Len(aReg)
		If aReg[nI][nPosMark] == .T. .AND. Alltrim(aReg[nI][nPosTipo]) == "FT"
			aadd(aFatura, {aReg[nI][nPosNumero],aReg[nI][nPosCliente],aReg[nI][nPosLoja],aReg[nI][nPosPrefixo],aReg[nI][nPosParcela],aReg[nI][nPosTipo],aReg[nI][nPosRecno]} )
			nCont++
		Endif
	Next

	If nCont == 0
		MsgInfo("Nenhum registro de fatura selecionado.","Atenção")
	else

		//ordeno o array de faturas por cliente
		ASort(aFatura,,,{|x,y| x[2] + x[3] + x[1] < y[2] + y[3] + y[1] })

		cCli			:= aFatura[1][2]
		cLojaCli		:= aFatura[1][3]
		aAuxFat 		:= {}
		nQtdFat			:= Len(aFatura)

		For nI := 1 To nQtdFat
			aadd(aAuxFat, {aFatura[nI][1],aFatura[nI][2],aFatura[nI][3],aFatura[nI][4],aFatura[nI][5],aFatura[nI][6]} )

			if nI+1 <= nQtdFat
				cCli			:= aFatura[nI+1][2]
				cLojaCli		:= aFatura[nI+1][3]
			endif

			if cCli+cLojaCli <> aFatura[nI][2]+aFatura[nI][3] .OR. nI == nQtdFat
				if U_TRETE044(cFilAnt, aAuxFat )					
					lEnvOk := .T.
				endif
				aAuxFat := {}
			endif
		Next nI

		if lEnvOk
			MsgInfo("Email(s) enviado(s) com sucesso!","Atenção")
		endif
	Endif

Return


User Function UFValAcess(cPrefixo,cNum,cParcela,cTipo,cCliFor,cLoja,cNatureza, lBaixados,cCodVa,cCarteira,dDtBaixa,aValAces,nMoedaTit,nMoedaBco,nTxMoeda,cIdFKD, lRetroativ)
	Local nTotVlAces := 0
	//TODO: o calculo de valores acessórios com lentidão...
	nTotVlAces := FValAcess(cPrefixo,cNum,cParcela,cTipo,cCliFor,cLoja,cNatureza, lBaixados,cCodVa,cCarteira,dDtBaixa,aValAces,nMoedaTit,nMoedaBco,nTxMoeda,cIdFKD, lRetroativ)
Return nTotVlAces

/*/{Protheus.doc} SM0MultiSel
Consulta Específica de Filial marcar 

@author thebr
@since 02/05/2019
@version 1.0
@return Nil
@type function
/*/
Static Function SM0MultiSel()

	Local nI
	Local aAreaSM0 		:= SM0->(GetArea())
	Local aInf			:= {}
	Local aDados		:= {}
	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",12,0},{"COL2","C",40,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Descrição",""}}
	Local nPosIt		:= 0
	Local cDBExt 		:= ".dbf"
	Local cReadVar 		:= "cGet8" //campo filial da tela principal

	Private cArqTrab	:= CriaTrab(aCampos) // Criando arquivo temporario
	Private oTempTable as object
	Private oDlgSM0
	Private oMarkSM0
	Private cMarcaSM0	 	:= "mk"
	Private lImpFechar	:= .F.
	Private oSayX1, oSayX2, oSayX3, oSayX4
	Private oTexto
	Private cTextoSM0	:= Space(40)
	Private nContSM0		:= 0
	Private cInf 		:= ""

	aInf := IIF(!Empty(&(cReadVar)),StrTokArr(AllTrim(&(cReadVar)),"/"),{})
	cInf := &(cReadVar)

	dbSelectArea("SM0")
	SM0->(dbGoTop())

	While SM0->(!EOF())
		If AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt)
			aAdd(aDados,{SM0->M0_CODFIL,SM0->M0_FILIAL})
		Endif

		SM0->(dbSkip())
	EndDo

	RestArea(aAreaSM0)

	//Retorna a extensão em uso para as tabelas acessadas através do driver ou RDD "DBFCDX"
	cDBExt := GetSrvProfString( "LocalDBExtension", ".dbf" ) //GetDBExtension()
	cDBExt := Lower( cDBExt )

	If cDBExt = '.dbf' .or. cDBExt = '.dtc' //dicionário não é DBF ou CTREE
		//cria a tabela temporaria: arquivo
		DBUseArea(.T.,,cArqTrab,"TRBAUX",If(.F. .OR. .F., !.F., NIL), .F.)  // Criando Alias para o arquivo temporario
	Else
		//cria a tabela temporaria: no banco de dados relacional da base do sistema
		oTempTable := FWTemporaryTable():New("TRBAUX")
		oTempTable:SetFields(aCampos)
		oTempTable:Create()
	EndIf

	DbSelectArea("TRBAUX")

	If Len(aDados) > 0
		For nI := 1 to Len(aDados)
			if Alltrim(xFilial("SE1")) == Alltrim(xFilial("SE1", aDados[nI][1])) //tratamento para só aparecer filiais que estão no mesmo compartilhamento
				TRBAUX->(RecLock("TRBAUX",.T.))
				If Len(aInf) > 0
					nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
					If nPosIt > 0
						TRBAUX->OK := "mk"
						nContSM0++
					Else
						TRBAUX->OK := "  "
					Endif
				Else
					TRBAUX->OK := "  "
				Endif
				TRBAUX->COL1 := aDados[nI][1]
				TRBAUX->COL2 := aDados[nI][2]
				TRBAUX->(MsUnlock())
			endif
		Next
	Else
		TRBAUX->(RecLock("TRBAUX",.T.))
		TRBAUX->OK		:= "  "
		TRBAUX->COL1	:= Space(6)
		TRBAUX->COL2 	:= Space(40)
		TRBAUX->(MsUnlock())
	Endif

	TRBAUX->(DbGoTop())

	DEFINE MSDIALOG oDlgSM0 TITLE "Seleção de Dados - Filiais Origem" From 000,000 TO 450,700 COLORS 0, 16777215 PIXEL

	@ 005, 005 SAY oSayX1 PROMPT "Descrição:" SIZE 060, 007 OF oDlgSM0 COLORS 0, 16777215 PIXEL
	@ 004, 050 MSGET oTexto VAR cTextoSM0 SIZE 200, 010 OF oDlgSM0 COLORS 0, 16777215 PIXEL Picture "@!"
	@ 005, 272 BUTTON oButtonX1 PROMPT "Localizar" SIZE 040, 010 OF oDlgSM0 ACTION LocalizaSM0(cTextoSM0) PIXEL

	//Browse
	oMarkSM0 := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarcaSM0,{020,005,190,348})
	oMarkSM0:bMark 				:= {|| xMarcaIt()}
	oMarkSM0:oBrowse:LCANALLMARK 	:= .T.
	oMarkSM0:oBrowse:LHASMARK    	:= .T.
	oMarkSM0:oBrowse:bAllMark 		:= {|| xMarcaT()}

	@ 193, 005 SAY oSayX2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlgSM0 COLORS 0, 16777215 PIXEL
	@ 193, 090 SAY oSayX3 PROMPT cValToChar(nContSM0) SIZE 040, 007 OF oDlgSM0 COLORS 0, 16777215 PIXEL

	//Linha horizontal
	@ 203, 005 SAY oSayX4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlgSM0 COLORS CLR_GRAY, 16777215 PIXEL

	@ 213, 272 BUTTON oButtonX2 PROMPT "Confirmar" SIZE 040, 010 OF oDlgSM0 ACTION CXFilAut() PIXEL
	@ 213, 317 BUTTON oButtonX3 PROMPT "Fechar" SIZE 030, 010 OF oDlgSM0 ACTION FXFilAut() PIXEL

	ACTIVATE MSDIALOG oDlgSM0 CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]

Return cInf

//-------------------------------------------------------------------
/*/{Protheus.doc} CXFilAut
Acao do botao Confirmar da funcao XFilAut
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CXFilAut()

	Local lAux 	:= .F.
	Local nAux	:= 0

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk"
			If !lAux
				cInf := AllTrim(TRBAUX->COL1)
				lAux := .T.
			Else
				cInf += "/" + AllTrim(TRBAUX->COL1)
			Endif
			nAux += Len(TRBAUX->COL1)
		EndIf

		TRBAUX->(dbSkip())
	EndDo

	FXFilAut()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FXFilAut
Acao do botao Fechar da funcao XFilAut
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FXFilAut()

	lImpFechar := .T.

	If Select("TRBAUX") > 0
		TRBAUX->(DbCloseArea())
	Endif

	//Retorna a extensão em uso para as tabelas acessadas através do driver ou RDD "DBFCDX"
	cDBExt := GetSrvProfString( "LocalDBExtension", ".dbf" ) //GetDBExtension()
	cDBExt := Lower( cDBExt )

	If cDBExt = '.dbf' .or. cDBExt = '.dtc' //dicionário não é DBF ou CTREE
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apagando arquivo temporario                                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		FErase(cArqTrab + GetDBExtension())
		FErase(cArqTrab + OrdBagExt())
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apagando arquivo temporario no banco de dados                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oTempTable:Delete()
	EndIf

	oDlgSM0:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} xMarcaIt
Acao ao selecionar item
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function xMarcaIt()

	If TRBAUX->OK == "mk"
		nContSM0++
	Else
		--nContSM0
	Endif

	oSayX3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} xMarcaT
Acao ao selecionar tudo
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function xMarcaT()

	Local lMarca 	:= .F.
	Local lNMARCA 	:= .F.

	nContSM0 := 0

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
				nContSM0++
				lMarca := .T.
			Endif
		Endif

		TRBAUX->(dbSkip())
	EndDo

	TRBAUX->(dbGoTop())

	oSayX3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Localiza
Acao ao selecionar Localizar
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LocalizaSM0(_cTexto)

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

Static Function MenusNfeFil(oMenuPai)
	
	Local aArea 	:= GetArea()
	Local aAreaSM0 	:= SM0->(GetArea())

	SM0->(dbSetOrder(1)) // CÓDIGO + Cod. Filial
	SM0->(DbGoTop())
	SM0->(DbSeek(cEmpAnt))

	While SM0->(!EOF()) .And. AllTrim(SM0->M0_CODIGO) == cEmpAnt
		
		oMenuPai:Add( TMenuItem():New(oMenuPai,Alltrim(SM0->M0_FILIAL)+' ('+Alltrim(SM0->M0_CODFIL)+')',,,,&('{|| CallNfeSefaz("'+Alltrim(SM0->M0_CODFIL)+'") }'),,,,,,,,,.T.) )

		SM0->(DbSkip())
	EndDo

	RestArea(aAreaSM0)
	RestArea(aArea)

Return

Static Function ChangeGrid()

	Local cOrdens := ""
	Local lConfirma := .F.
	Local oFont1 := TFont():New("MS Sans Serif",,022,,.T.,,,,,.F.,.F.)
	Private lRestore := .F.
	Private oDlgOrdCols
	Private oMsGridCols
	Private aBkpCfgCampos 

	//verifico se usuario tem salvo o profile
	cChave := FWGetProfString("TRETE017OC", "ORDGDCOLS", "NOCONFIG", .T.)
	if !empty(cChave) .AND. cChave <> "NOCONFIG"
		aBkpCfgCampos := OrdByProfile(cChave, .F.)
	else
		aBkpCfgCampos := aClone(aCfgCampos)
	endif

	DEFINE MSDIALOG oDlgOrdCols TITLE "Configurações da Tela" FROM 000, 000  TO 500, 400 COLORS 0, 16777215 PIXEL

    @ 007, 008 SAY oSay1 PROMPT "Ordenar Colunas" SIZE 097, 017 OF oDlgOrdCols FONT oFont1 COLORS 0, 16777215 PIXEL
    @ 031, 006 GROUP oGroup1 TO 223, 191 PROMPT "Ordene as colunas clicando as setas" OF oDlgOrdCols COLOR 0, 16777215 PIXEL
    
	GridOrdemCol() //monta grid

    @ 229, 132 BUTTON oBtnCG1 PROMPT "Salvar Ordenação" SIZE 055, 012 OF oDlgOrdCols PIXEL ACTION (lConfirma := .T., oDlgOrdCols:end())
    @ 229, 073 BUTTON oBtnCG2 PROMPT "Restaurar Padrão" SIZE 055, 012 OF oDlgOrdCols PIXEL ACTION RestoreCpo()
    @ 229, 006 BUTTON oBtnCG3 PROMPT "Cancelar" SIZE 040, 012 OF oDlgOrdCols PIXEL ACTION oDlgOrdCols:end()

  	ACTIVATE MSDIALOG oDlgOrdCols CENTERED

	if lConfirma
		
		if lRestore
			FwWriteProfString( "TRETE017OC", "ORDGDCOLS", "", .T. )
		else
			cOrdens := ""
			aEval(aBkpCfgCampos[4], {|cVar| cOrdens += cVar+"/" }) //posição 4 é o aVarsPos
			cOrdens := SubStr(cOrdens,1,len(cOrdens)-1) //retiro a ultima barra
			
			//salvo no profile do usuario
			FwWriteProfString( "TRETE017OC", "ORDGDCOLS", cOrdens, .T. )
		endif
		MsgInfo("Configurações salvas com sucesso! Feche a tela e abra novamente para ver o resultado.")
	endif
			

Return

Static Function GridOrdemCol()

	Local nX := 1
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aAlterFields := {}

	//Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
	//                 SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})

	Aadd(aHeaderEx,{" ","UP",'@BMP',3,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aHeaderEx,{" ","DOWN",'@BMP',3,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aHeaderEx,{'Coluna','COLUNA','',20,0,'','€€€€€€€€€€€€€€','C','','','',''})

	for nX := 1 to len(aBkpCfgCampos[1]) //começo do 3 pois não considero o mark nem legenda
		if aBkpCfgCampos[4][nX] == "nPosMark"
			Aadd(aColsEx, {"UP2", "DOWN2", "Marcador", .F.} )
		elseif aBkpCfgCampos[4][nX] == "nPosLegend"
			Aadd(aColsEx, {"UP2", "DOWN2", "Legenda", .F.} )
		else
			Aadd(aColsEx, {"UP2", "DOWN2", aBkpCfgCampos[1][nX], .F.} )
		endif
	next nX

	oMsGridCols := MsNewGetDados():New( 041, 008, 219, 189, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgOrdCols, aHeaderEx, aColsEx)
	oMsGridCols:oBrowse:bLDblClick := {|| ColUpDown(oMsGridCols:oBrowse:nColPos) }

Return 

//1=Up;2=Down
Static Function ColUpDown(nOpc)

	Local nX
	Local xContent 

	if nOpc == 1 //up
		if oMsGridCols:nAt <> 1 //se ja for a primeira coluna, nada faz
			//ajusto o aCols da tela configuração
			xContent := oMsGridCols:aCols[oMsGridCols:nAt-1][3]
			oMsGridCols:aCols[oMsGridCols:nAt-1][3] := oMsGridCols:aCols[oMsGridCols:nAt][3]
			oMsGridCols:aCols[oMsGridCols:nAt][3] := xContent

			for nX := 1 to len(aBkpCfgCampos) //aqui eu somo 1 por que eu desconsidero as 2 primeiras posições (mark e legenda)
				xContent := aBkpCfgCampos[nX][oMsGridCols:nAt-1]
				aBkpCfgCampos[nX][oMsGridCols:nAt-1] := aBkpCfgCampos[nX][oMsGridCols:nAt]
				aBkpCfgCampos[nX][oMsGridCols:nAt] := xContent
			next nX

			oMsGridCols:nAt -= 1
			oMsGridCols:oBrowse:nAt -= 1
		endif
	else //down
		if oMsGridCols:nAt <> len(oMsGridCols:aCols) //se for a ultima coluna, nada faz
			//ajusto o aCols da tela configuração
			xContent := oMsGridCols:aCols[oMsGridCols:nAt+1][3]
			oMsGridCols:aCols[oMsGridCols:nAt+1][3] := oMsGridCols:aCols[oMsGridCols:nAt][3]
			oMsGridCols:aCols[oMsGridCols:nAt][3] := xContent

			for nX := 1 to len(aBkpCfgCampos) //aqui eu somo 3 por que eu desconsidero as 2 primeiras posições (mark e legenda)
				xContent := aBkpCfgCampos[nX][oMsGridCols:nAt+1]
				aBkpCfgCampos[nX][oMsGridCols:nAt+1] := aBkpCfgCampos[nX][oMsGridCols:nAt]
				aBkpCfgCampos[nX][oMsGridCols:nAt] := xContent
			next nX

			oMsGridCols:nAt += 1
			oMsGridCols:oBrowse:nAt += 1
		endif
	endif

	oMsGridCols:oBrowse:Refresh()

	lRestore := .F.

Return

Static Function OrdByProfile(cChave, lSetPositions)

	Local aRet := {}
	Local nX
	Local nPosAux := 0
	Local aCabec := {}
	Local aSizes := {}
	Local aLinEmpty := {}
	Local aVarsPos := StrToKArr(cChave, "/")

	Default lSetPositions := .T.

	//coloco as posições conforme foi salvo
	for nX := 1 to len(aVarsPos)
		nPosAux := aScan(aCfgCampos[4], aVarsPos[nX])
		if nPosAux > 0
			aadd(aCabec, aCfgCampos[1][nPosAux])
			aadd(aSizes, aCfgCampos[2][nPosAux])
			aadd(aLinEmpty, aCfgCampos[3][nPosAux])
		endif
	next nX

	//verifico se há alguma coluna no aCfgCampos[4] que não estava salvo no profile
	for nX := 1 to len(aCfgCampos[4])
		nPosAux := aScan(aVarsPos, aCfgCampos[4][nX]) 
		if nPosAux == 0 
			aadd(aCabec, aCfgCampos[1][nX])
			aadd(aSizes, aCfgCampos[2][nX])
			aadd(aLinEmpty, aCfgCampos[3][nX])
			aadd(aVarsPos, aCfgCampos[4][nX])
		endif
	next nX

	aRet := {aCabec, aSizes, aLinEmpty, aVarsPos}

	if lSetPositions
		for nX := 1 to len(aRet[4])
			&(aRet[4][nX]) := nX
		next nX
	endif

Return aRet

Static function RestoreCpo()

	Local nX

	oMsGridCols:aCols := {}

	for nX := 1 to len(aCfgCpDefault[4]) //começo do 3 pois não considero o mark nem legenda
		if aCfgCpDefault[4][nX] == "nPosMark"
			Aadd(oMsGridCols:aCols, {"UP2", "DOWN2", "Marcador", .F.} )
		elseif aCfgCpDefault[4][nX] == "nPosLegend"
			Aadd(oMsGridCols:aCols, {"UP2", "DOWN2", "Legenda", .F.} )
		else
			Aadd(oMsGridCols:aCols, {"UP2", "DOWN2", aCfgCpDefault[1][nX], .F.} )
		endif
	next nX

	oMsGridCols:GoTop()
	oMsGridCols:oBrowse:Refresh()

	aBkpCfgCampos := aClone(aCfgCpDefault)
	lRestore := .T.

Return

Static Function TelaVenc(dDtVenFlx)

	Local lConfirma := .F.
	Local oFont1 := TFont():New("MS Sans Serif",,022,,.T.,,,,,.F.,.F.)
	Local oGDtVen
	Local oSay1
	Private oDlgOrdCols

	DEFINE MSDIALOG oDlgOrdCols TITLE "Faturamento - Alterar Vencimento" FROM 000, 000  TO 200, 400 COLORS 0, 16777215 PIXEL

    @ 007, 010 SAY oSay1 PROMPT "Geração de Fatura - Alt. Vencimento" SIZE 170, 017 OF oDlgOrdCols FONT oFont1 COLORS 0, 16777215 PIXEL

    @ 030, 015 SAY oSay1 PROMPT "Informe a data de vencimento para a(s) fatura(s) a gerar:" SIZE 169, 007 OF oDlgOrdCols COLORS 0, 16777215 PIXEL 

	@ 045, 015 SAY oSay1 PROMPT "Data Venc.: " SIZE 169, 007 OF oDlgOrdCols COLORS 0, 16777215 PIXEL 
	@ 043, 070 MSGET oGDtVen VAR dDtVenFlx SIZE 070, 010 OF oDlgOrdCols COLORS 0, 16777215 PIXEL VALID (dDtVenFlx:=DataValida(dDtVenFlx)) HASBUTTON
    
 	@ 065, 010 SAY oSay1 PROMPT "Haverá o faturamento dos registros selecionados, deseja continuar?" SIZE 169, 007 OF oDlgOrdCols COLORS 0, 16777215 PIXEL 

    @ 080, 132 BUTTON oBtnCG1 PROMPT "Confirmar" SIZE 055, 012 OF oDlgOrdCols PIXEL ACTION iif(!empty(dDtVenFlx) .AND. dDtVenFlx>=dDataBase,(lConfirma := .T., oDlgOrdCols:end()),MsgInfo("Informe uma data maior ou igual a data atual.","Data"))
    @ 080, 010 BUTTON oBtnCG3 PROMPT "Cancelar" SIZE 040, 012 OF oDlgOrdCols PIXEL ACTION oDlgOrdCols:end()

  	ACTIVATE MSDIALOG oDlgOrdCols CENTERED

Return lConfirma


Static Function MonitorNotas(aFaturas)
	
	Local nI
	Local nCont 	:= 0

	Default aFaturas := {}

	if empty(aFaturas)
	
		For nI := 1 To Len(aReg)
			If aReg[nI][nPosMark] == .T.
				nCont++
				If AllTrim(aReg[nI][nPosTipo]) == "FT" // Fatura
					//Número 				Cliente 				Loja			 Prefixo				 Parcela 				Tipo
					AAdd(aFaturas,{aReg[nI][nPosNumero],aReg[nI][nPosCliente],aReg[nI][nPosLoja],aReg[nI][nPosPrefixo],aReg[nI][nPosParcela],aReg[nI][nPosTipo]})
				Endif
			Endif
		Next

		If nCont > 0 .And. Len(aFaturas) > 0
			if nCont <> Len(aFaturas)
				MsgInfo("Dentre o(s) registro(s) selecionado(s), há titulos que não se trata de uma fatura, e serão desconsiderados.","Atenção")
			endif
			U_TRETE049(aFaturas)
		ElseIf nCont > 0 .And. Len(aFaturas) == 0
			MsgInfo("Nenhum título do tipo fatura selecionado.","Atenção")
		Else
			MsgInfo("Nenhum registro selecionado.","Atenção")
		Endif

	else
		U_TRETE049(aFaturas, .T.)
	endif

Return

#INCLUDE "totvs.ch"
#INCLUDE "hbutton.ch"
#INCLUDE "TbiConn.ch"


//-------------------------------------------------------------------
/*/{Protheus.doc} USX6POST
Parametros das Rotinas
aRotUsu ( vetor com as rotinas que o usuario tera acesso ) 
Exemplo:    aRotUsu := {"001","004","005",...}
			aRotUsu := {"*"} AXTABELA (todos parametros)

@author  author
@since   date
@version version
@obs
Para inserir nova rotina, eh necessario incluir a mesma no
vetor "aRotTot", atribuir todos os parametros da rotina na
variavel "cParamet" e documentar nas "Rotinas disponiveis"

Rotinas disponiveis:
	001 - Posto Inteligente - Totvs PDV 
/*/
//-------------------------------------------------------------------
User Function USX6POST(aRotUsu)

	Local nI        := 0
	Local aMarcadas := {}
	Local lOpen   	:= .F.
	Local aRecnoSM0 := {}
	Local lShared   := .T. //Caso verdadeiro, indica que a tabela deve ser aberta em modo compartilhado, isto é, outros processos também poderão abrir esta tabela.

	Local aSay		:= {}
	Local aButton	:= {}
	Local lOk		:= .F.
	Local cTitulo	:= "ATUALIZAÇÃO DE PARÂMETROS - POSTO INTELIGENTE"
	Local cDesc1	:= "Esta rotina tem como função fazer a atualização dos parâmetros: SX6"
	Local cDesc2	:= ""
	Local cDesc3	:= ""
	Local cDesc4	:= ""
	Local cDesc5	:= ""
	//Local cDesc6	:= ""
	//Local cDesc7	:= ""

	Public oMainWnd := NIL

	#IFDEF TOP
		TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF

	__cInterNet := NIL
	__lPYME     := .F.

	Set Dele On //-- habilita filtro do campo DELET

// Mensagens de Tela Inicial
	aAdd( aSay, "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS - POSTO INTELIGENTE")
	aAdd( aSay, "" )
	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )
	aAdd( aSay, cDesc4 )
	aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

	FormBatch(  cTitulo,  aSay,  aButton )

	If lOk

		aMarcadas := U_UPDESEMP(lShared)

		If !Empty( aMarcadas ) .and. ( lOpen := U_UPDOPSM0(lShared) ) //!Empty(cGetEmp) .and. !Empty(cGetFil)

			dbSelectArea( "SM0" )
			dbGoTop()

			While !SM0->( EOF() )
				// So adiciona no aRecnoSM0 se a empresa for diferente
				If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
						.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
					aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
				EndIf
				SM0->( dbSkip() )
			End

			SM0->( dbCloseArea() )

			If lOpen

				For nI := 1 To Len( aRecnoSM0 )

					If !( lOpen := U_UPDOPSM0(lShared) )
						Help(NIL, NIL, "ATENÇÃO", NIL, "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
						Exit
					EndIf

					SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

					//RpcSetType( 3 )
					//RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

					cEmpAnt := AllTrim(SM0->M0_CODIGO)
					cFilAnt := AllTrim(SM0->M0_CODFIL)

					//-- Preparar ambiente local na retagauarda
					RpcSetType(3)
					PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

					lMsFinalAuto := .F.
					lMsHelpAuto  := .F.

				DoTelaSX6(aRotUsu)

			Next nI

		EndIf
	EndIf

EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} DoTelaSX6
DoTelaSX6: mostra a tela de parametros
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function DoTelaSX6(aRotUsu)

	Local aObjects  := {} , aPos := {} , aInfo := {}
	Local aSizeHalf := MsAdvSize(.T.)  // Tamanho Maximo da Janela (.T.=TOOLBAR,.F.=SEM TOOLBAR)

	Local nI        := 0
	Local cRot      := ""

	Private overd   := LoadBitmap( GetResources(), "BR_verde")    // parametro existente na base
	Private overm   := LoadBitmap( GetResources(), "BR_vermelho") // parametro nao existente na base
	Private aVetPar    := {{"overm","","","",""}} // vetor dos parametros
	Private aRot    := {}   // Rotinas disponiveis
	Private aRotTot := {""} // Todas as Rotinas
	Private oParRot, oLbPar

	Default aRotUsu := {}   // Parametro - Rotinas que o usuario tem acesso

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Rotinas               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aAdd(aRotTot,"001="+"Posto Inteligente - Totvs PDV") //
	aAdd(aRotTot,"002="+"Preços em Níveis")
	aAdd(aRotTot,"003="+"Naturezas Financeiras")
	aAdd(aRotTot,"004="+"LARCO")
	aAdd(aRotTot,"005="+"Parâmetros de Implantação")

	If len(aRotUsu) == 0 // Nao foi passado nenhuma rotina como parametro
		aRot := aClone(aRotTot) // disponibilizar todas as rotinas
		cRot := SubStr(aRotTot[1],1,3)
	Else // Foi passada rotinas como parametro
		If len(aRotUsu) == 1 // Apenas uma rotina
			cRot := SubStr(aRotUsu[1],1,3)
			U_USX6POS3(cRot,.f.) // Filtrar parametros da rotina
		Else // Varias rotinas
			aRot := {""}
		EndIf
		For ni := 1 to len(aRotTot)
			If Ascan(aRotUsu,SUBSTR(aRotTot[ni],1,3)) > 0 // verificar se usuario pode acessar a rotina
				aAdd(aRot,aRotTot[ni]) // adicionar a rotina
			EndIf
		Next
	EndIf

	If aSizeHalf[3] = 0
//aSizeHalf[1] := 0   //1 - Linha inicial
//aSizeHalf[2] := 0   //2 - Coluna Inicial
		aSizeHalf[3] := 970/2 //3 - Linha Final
		aSizeHalf[4] := 624/2 //4 - Coluna Final

		aSizeHalf[5] := 970 //5 - Separação X
		aSizeHalf[6] := 624 + 30 //6 - Separação Y
//aSizeHalf[7] //7 - Separação X da borda (Opcional)
//aSizeHalf[8] //7 - Separação X da borda (Opcional)
	EndIf

//Alert( "aSizeHalf: " + CRLF + U_XtoStrin(aSizeHalf) )

	aInfo := { aSizeHalf[ 1 ], aSizeHalf[ 2 ], aSizeHalf[ 3 ], aSizeHalf[ 4 ], 3, 3 } // Tamanho total da tela
	aObjects := {}
	AAdd( aObjects, { 0, 30, .T. , .F. } ) // EnchoiceBar
	AAdd( aObjects, { 0, 21, .T. , .F. } ) // Pesquisar
	AAdd( aObjects, { 0, 10, .T. , .T. } ) // ListBox
	aPos := MsObjSize( aInfo, aObjects )

	//
	DEFINE MSDIALOG oParRot TITLE ("Parametros da Rotina - Empresa : " + SM0->M0_CODIGO + "/" + AllTrim(SM0->M0_NOME)) FROM aSizeHalf[7],0 TO aSizeHalf[6],aSizeHalf[5] /*OF oMainWnd*/ PIXEL // Parametros da Rotina
	oParRot:lEscClose := .F.
	@ aPos[2,1]+00,aPos[2,2]+00 TO aPos[2,1]+21,85 LABEL "Parametro existente na Base?" OF oParRot PIXEL // Parametro existente na Base?
	@ aPos[2,1]+10,aPos[2,2]+14 BITMAP OXverd RESOURCE "BR_verde" OF oParRot NOBORDER SIZE 10,10 PIXEL
	@ aPos[2,1]+10,aPos[2,2]+24 SAY "Sim" SIZE 30,8 OF oParRot PIXEL COLOR CLR_BLUE // Sim
	@ aPos[2,1]+10,aPos[2,2]+47 BITMAP OXverm RESOURCE "BR_vermelho" OF oParRot NOBORDER SIZE 10,10 PIXEL
	@ aPos[2,1]+10,aPos[2,2]+57 SAY "Nao" SIZE 30,8 OF oParRot PIXEL COLOR CLR_BLUE // Nao
	@ aPos[2,1]+00,aPos[2,2]+85 TO aPos[2,1]+21,aPos[2,4] LABEL "Rotina" OF oParRot PIXEL // Rotina
	@ aPos[2,1]+07,aPos[2,2]+88 MSCOMBOBOX oRot VAR cRot SIZE aPos[2,4]-93,08 COLOR CLR_BLACK ITEMS aRot OF oParRot PIXEL ON CHANGE U_USX6POS3(cRot,.t.) WHEN len(aRot) > 1
	@ aPos[3,1],aPos[3,2] LISTBOX oLbPar FIELDS HEADER "","Parametro","Tipo","Conteudo","Descricao" COLSIZES 10,25,20,60,120 SIZE aPos[3,4]-04,aPos[3,3]-45 OF oParRot PIXEL ON DBLCLICK U_USX6POS1(oLbPar:nAt)
	oLbPar:bHeaderClick := {|oObj,nCol| U_USX6POS2(nCol) , } // Ordenar Parametros
	oLbPar:SetArray(aVetPar)
	oLbPar:bLine := { || { &(aVetPar[oLbPar:nAt,1]) , aVetPar[oLbPar:nAt,2] , aVetPar[oLbPar:nAt,3] , aVetPar[oLbPar:nAt,4] , aVetPar[oLbPar:nAt,5] }}
	ACTIVATE MSDIALOG oParRot CENTER ON INIT EnchoiceBar(oParRot,{|| oParRot:End() },{ || oParRot:End()},,)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} USX6POS1
Altera conteudo do Parametro 
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function USX6POS1(nLinha)
	Local aRet      := {}
	Local aParamBox := {}
	Local cMascara  := ""
	Local xConteud  := ""
	Local aPars 	:= {}
	Local lExiste	:= (aVetPar[nLinha,1] == "overd") // Parametro existente na Base

	Local cAliasSX6 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	// abre o dicionário SX6
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)
	lOpen := Select(cAliasSX6) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf

	xConteud := PADR(aVetPar[nLinha,4],250) //tamanho do X6_CONTEUD

	Do Case
	Case aVetPar[nLinha,3] == "C" // Caracter
		cMascara := ""
		xConteud := left(xConteud+space(300),len((cAliasSX6)->&("X6_CONTEUD")))
	Case aVetPar[nLinha,3] == "N" // Numerico
		cMascara := "@E 9999999999999999999999999"
	Case aVetPar[nLinha,3] == "D" // Data
		cMascara := "@D"
		xConteud := left(xConteud+space(10),len((cAliasSX6)->&("X6_CONTEUD")))
	Case aVetPar[nLinha,3] == "L" // Logico
		cMascara := "@!"
		xConteud := left(xConteud+space(3),3)
	Otherwise
		aVetPar[nLinha,3] := " "
	EndCase

	AADD(aParamBox,{ 1,"Parametro",aVetPar[nLinha,2],"@!","","",".F.",50,.t.}) // Parametro
	AADD(aParamBox,{ 1,"Tipo",aVetPar[nLinha,3],"@!","","",iif(lExiste,".F.",".T."),20,.t.}) // Tipo
	AADD(aParamBox,{ 1,"Conteudo",xConteud,cMascara,"","","",120,.f.}) // Conteudo
	AADD(aParamBox,{11,"Descricao",aVetPar[nLinha,5],"",iif(lExiste,".F.",".T."),.t.}) // Descricao

	If ParamBox(aParamBox,"Parametro",@aRet,,,,,,,,.f.) // Parametro
		If lExiste
			aVetPar[nLinha,4] := aRet[03] // Atualizar vetor no listbox conteúdo
			PutMvPar(aVetPar[nLinha,2],aRet[03]) // Gravar conteudo no parametro
		Else
			aVetPar[nLinha,1] := "overd" // Atualiza vertor no listbox legenda
			aVetPar[nLinha,3] := aRet[02] // Atualizar vetor no listbox tipo
			aVetPar[nLinha,4] := aRet[03] // Atualizar vetor no listbox conteúdo
			aVetPar[nLinha,5] := aRet[04] // Atualizar vetor no listbox descricao
			aAdd(aPars, {aVetPar[nLinha,2], aRet[02], aRet[04], PADR(aRet[03],250)} )
			U_zCriaPar(aPars)
		EndIf
	EndIf

Return()

/*/{Protheus.doc} U_zCriaPar
Função para criação de parâmetros (SX6)
@type function
@author Totvs GO
@since 21/08/2019
@version 1.0
    @param aPars, Array, Array com os parâmetros do sistema
    @example
    U_zCriaPar(aParametros)
    
    @obs Abaixo a estrutura do array:
        [01] - Parâmetro (ex.: "MV_X_TST")
        [02] - Tipo (ex.: "C")
        [03] - Descrição (ex.: "Parâmetro Teste")
        [04] - Conteúdo (ex.: "123;456;789")
/*/

User Function zCriaPar(aPars)
	Local nAtual	:= 0
	Local aArea		:= GetArea()
	//Local aAreaX6	:= SX6->(GetArea())
	
	Local cAliasSX6 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela
	Default aPars	:= {}

	// abre o dicionário SX6
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)
	lOpen := Select(cAliasSX6) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX6)
	(cAliasSX6)->( DbSetOrder( 1 ) ) //X6_FIL+X6_VAR
	(cAliasSX6)->( DbGoTop() )

	//Percorrendo os parâmetros e gerando os registros
	For nAtual := 1 To Len(aPars)
		//Se não conseguir posicionar no parâmetro cria
		If !(cAliasSX6)->( dbSeek(xFilial()+aPars[nAtual][1]) )
			RecLock( cAliasSX6, .T. )
			//Geral
			(cAliasSX6)->&("X6_VAR")     := aPars[nAtual][1]
			(cAliasSX6)->&("X6_TIPO")    := aPars[nAtual][2]
			(cAliasSX6)->&("X6_PROPRI")  := "U"
			//Descrição
			(cAliasSX6)->&("X6_DESCRIC") := SubStr(aPars[nAtual][3],1,50)
			(cAliasSX6)->&("X6_DESC1")   := SubStr(aPars[nAtual][3],51,100)
			(cAliasSX6)->&("X6_DESC2")   := SubStr(aPars[nAtual][3],101,150)
			//Conteúdo
			(cAliasSX6)->&("X6_CONTEUD") := aPars[nAtual][4]
			SX6->(MsUnlock())
		EndIf
	Next
	
	DbCommitAll()
	DbUnlockAll()
	// FECHA O ARQUIVO DE TRABALHO
    DbCloseArea()

	//RestArea(aAreaX6)
	RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} USX6POS2
Ordenar listbox - vetor dos Parametros
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function USX6POS2(nCol)
	If nCol > 1
		Asort(aVetPar,,,{|x,y| x[nCol] < y[nCol] })
		oLbPar:Refresh()
		oLbPar:SetFocus()
	EndIf
Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} USX6POS3
Carrega os Parametros de uma determinada rotina
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function USX6POS3(cRot,lRefr)
	Local ni       := 0
	Local cParamet := "" // Parametro(10 posicoes) + / ...
	Local aParamet := {}
	Local aListPar := {} //nome, tipo, conteudo, descricao (150 caracteres)

	Local cAliasSX6 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela
	Local bGetMvFil	:= {|cParametro,lHelp,cDefault,cFil| GetMV(cParametro,lHelp,cDefault,cFil) }

	// abre o dicionário SX6
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)
	lOpen := Select(cAliasSX6) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	
	aVetPar := {} //zero o array do LISTBOX

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Parametros por Rotina ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Do Case

	Case cRot == "*" // Todos os parametros da BASE
		DbSelectArea(cAliasSX6)
		(cAliasSX6)->( DbSetOrder( 1 ) ) //X6_FIL+X6_VAR
		(cAliasSX6)->( DbGoTop() )
		While !Eof()
			aAdd(aVetPar,{ "overd" , (cAliasSX6)->&("X6_VAR") , (cAliasSX6)->&("X6_TIPO") , Alltrim(X6Conteud()) , Alltrim(X6Descric())+" "+Alltrim(X6Desc1())+" "+Alltrim(X6Desc2()) })
			dbskip()
		Enddo

	Case cRot == "001" // Posto Inteligente - Totvs PDV

		// Lista dos parametros encontrados no projeto tpdvposto
		cParamet += "ES_AJUS054/ES_ALCADA /ES_DBTSS  /ES_IPTSS  /ES_NWLTTSS/ES_PORTTSS/ESP_MOTOR /ESP_TRANSP/ESP_VEICUL/ESP_XAGLUT/" 
		cParamet += "MV_LJPOSTO/MRPC_CAIXA/MV_1DUP   /MV_ARREFAT/MV_CFOPREM/MV_CFOPTRA/MV_CLIPAD /MV_CODREG /MV_COMBUS /MV_DATAFIN/" 
		cParamet += "MV_DATAREC/MV_DEVNCC /MV_ENVCDGE/MV_ESPECIE/MV_ESTADO /MV_FTTEFGU/MV_FTTEFLI/MV_ICSTDEV/MV_IPIBENE/MV_IPIDEV /" 
		cParamet += "MV_LIBCHEQ/MV_LJAMBIE/MV_LJCHGDV/MV_LJCMPCR/MV_LJCMPNC/MV_LJCNVDA/MV_LJCNVDA/MV_LJCOLOR/MV_LJCONDE/MV_LJCPNCC/" 
		cParamet += "MV_LJFCVDA/MV_LJINTER/MV_LJINTER/MV_LJMULTA/MV_LJSTPRT/MV_LJTPCOM/MV_LJTPDES/MV_LJTRDIN/" 
		cParamet += "MV_LJTROCO/MV_LJTXNFE/MV_LJVLNCC/MV_LOJAPAD/MV_MENBOL1/MV_MENBOL2/MV_MENBOL3/MV_MODALID/MV_MODNFCE/MV_MOEDA1 /" 
		cParamet += "MV_NFCEDES/MV_NFCEEXC/MV_NFCEIMP/MV_NFCEURL/MV_NFCEUTC/MV_NUMFAT /MV_RELACNT/MV_RELAUTH/MV_RELPSW /MV_MOEDAP1/" 
		cParamet += "MV_RELSERV/MV_SIMB1  /MV_SPEDEXC/MV_SPEDURL/MV_TABPAD /MV_TESSAI /MV_TXPER  /MV_USACRED/MV_VENDPAD/MV_VERNFCE/" 
		cParamet += "MV_XALTSAC/MV_XATAJAB/MV_XATUPRC/MV_XBCOCDV/MV_XBOMBAR/MV_XCALVEN/MV_XCCDVSP/MV_XCCPDV /MV_XCODBAR/MV_XCOMBUS/" 
		cParamet += "MV_XDIASVC/MV_XDIASVS/MV_XDIFMAX/MV_XDIRBMO/MV_XDIRBOL/MV_XDIRDAN/MV_XDIRFAT/MV_XDIRSER/MV_XDIRSYS/MV_XDIVERG/" 
		cParamet += "MV_XENVARQ/MV_XFCHHMI/TP_FPGCONV/MV_XFPGCLI/MV_XFPGFAT/MV_XFUNSLI/MV_XGERANF/MV_XGRARLA/MV_XIMPEXT/MV_XIMPPAD/" 
		cParamet += "MV_XINCLEJ/MV_XINCSLI/MV_XLMCORG/MV_XLOCREC/MV_XMAILCC/MV_XMAILEX/MV_XMAILFT/MV_XMAILIN/MV_XMARAJO/MV_XMAXDIV/" 
		cParamet += "MV_XMAXFUS/MV_XMRGVAL/MV_XMSGADI/MV_XMSGARL/MV_XMSGCUP/MV_XMSGTER/MV_XVOPCMP/MV_XCONFCX/MV_XCONSME/" 
		cParamet += "MV_XNFACOB/MV_XNFCONT/MV_XNFRECU/MV_XNGDESC/MV_XNOMEMP/MV_XNROTEN/MV_XOBSFAT/MV_XPAGFIL/MV_XPAGPRE/MV_XPAGTIP/" 
		cParamet += "MV_XPDFTAB/MV_XPERCGP/MV_XPFXCOM/MV_XPOSTO /MV_XPRFXRS/MV_XRATAUT/MV_XRATFCP/MV_XRECFIL/MV_XRECPRE/MV_XRECTIP/" 
		cParamet += "MV_XREPSAE/MV_XSEE   /MV_XSERFAT/MV_XSRVPDV/MV_XTABPRO/MV_XTFPCLI/MV_XTMBREL/MV_XTMFREL/MV_XTMGANH/MV_XTMPBOL/" 
		cParamet += "MV_XTMPERD/MV_XTMPFAT/MV_XTPFTAU/MV_XTPLIVR/MV_XTPPROD/MV_XTXPER /MV_XTXRENE/MV_XUSITUA/MV_XVENCCF/" 
		cParamet += "MV_XVIASNP/MV_XVLDCXA/MV_XVLDDIV/TP_ACTBXTR/TP_ACTCF  /TP_ACTCHT /TP_ACTCMP /TP_ACTNP  /TP_ACTSQ  /TP_ACTVCR /" 
		cParamet += "TP_ACTVLH /TP_ACTVLS /TP_ACTDP  /MV_LJADFLD/MV_XADMFID/MV_XDTABAS/MV_XHRABAS/MV_XMNABAS/MV_LJORCAM/MV_XDIASPR/" 
		cParamet += "MV_LJORCAA/TP_ACTORC /MV_LJORPAR/MV_CXLOJA /MV_LJALTCX/MV_XCONDCF/MV_XUSRADM/ES_ALCDES /ES_ALCDPN /ES_ALCLIM /" 
		cParamet += "ES_ALCCMP /ES_ALCSAQ /ES_ALCDCX /ES_ALCDTIT/ES_ALCLOG /MV_XPE1300/MV_XMONMIN/MV_XVLDDEV/MV_XQTD1  /TP_SSVIASA/" 
		cParamet += "MV_XMAILFP/MV_XDTMAX /MV_XVERCTB/MV_XTIPSAC/MV_XMOTEXC/MV_XDECIMP/MV_XMRGVAL/MV_LJFISMS/TP_ACESSTF/TP_CCESEXP/" 
		cParamet += "MV_XCRCLIP/MV_XFUNBOL/MV_XTPCRC /ES_ALCLID /MV_VLDDTAB/MV_DTUVABA/ES_LOGCCX /MV_XGERENT/" 
		cParamet += "MV_XPECRC /TP_MULTAFE/MV_XQTQLMC/MV_LJADMFI/MV_TELAFIN/MV_XBLQAI0/MV_LJORCAM/MV_LJORCAA/MV_XCARGVD/MV_XBICMOV/" 
		cParamet += "TP_RIDENTF/MV_LOJANF /MV_SERIE  /MV_FISNOTA/MV_LJTNINT/MV_LJIMPCR/ES_ALCTRC /MV_XAVINEX/MV_XPENFCE/MV_XURLTSS/"
		cParamet += "MV_XIMPDNF/MV_XINFVEN/MV_XSELADM/MV_XIDTSA3/TP_BLQCANC/TP_HCTRASQ/TP_DA4SOBR/TP_ZERAUF2/TP_IMPAGLC/TP_DETTVEN/"
		cParamet += "TP_IMPOBSC/TP_FCHABAS/TP_VLEMTCF/TP_IMPAFER/MV_XSUGDTN/MV_XVALCON/ES_CONFPEN/MV_XVADTCX/TP_VLCCANC/MV_LJTPCAN/"
		cParamet += "MV_XQTMPDV/TP_VLIDENT/TP_ACTCT/MV_LJNSU/MV_LJLVFIS/MV_ULTAQUI/MV_XAJR411/MV_XTVIAVH/MV_XVIASAF/MV_XTVIAAF"
		cParamet += "MV_XFTVLLA/MV_XT028GC/MV_XDIFMAN/MV_XQTCEST/MV_XCBCNEW/MV_XFVALDP/MV_XTPTITB/MV_XIMP2/MV_XTLDLMC/MV_XMAILAS"
		cParamet += "MV_XTSFDEV/MV_XCNDPDE/MV_XAJNFCU/MV_XMAILVI/MV_XRECSE1/MV_XLMCTQS/TP_MAILJUR/MV_XDTRHST/MR_XCODPRO"

		// lista de parametros com valores defaults
		// aListPar -> [nome], [tipo], [conteudo], [descricao] (150 caracteres)
		aadd(aListPar, { "MV_LJPOSTO", "L", ".T.", "Habilita Posto de Combustível no Totvs PDV." })
		aadd(aListPar, { "MV_XPOSTO ", "L", ".T.", "Habilita Posto de Combustível (Posto Inteligente)." })
		aadd(aListPar, { "MV_XSRVPDV", "L", ".T.", "Servidor PDV ou base Totvs PDV ? (default .T.)" })
		aadd(aListPar, { "ES_AJUS054", "L", ".T.", "Atualiza a tabela SPED054, quando ocorrer recuperação de venda ? (default .T.)" })
		aadd(aListPar, { "ES_ALCADA ", "L", ".F.", "Habilita controle de alcadas ? (default .F.)" })
		aadd(aListPar, { "ES_ALCDES ", "L", ".F.", "Habilita controle de alcadas de desconto? (default .F.)" })
		aadd(aListPar, { "ES_ALCDPN ", "L", ".F.", "Habilita controle de alcadas de desconto sobre preço negociado? (default .F.)" })
		aadd(aListPar, { "ES_ALCLIM ", "L", ".F.", "Habilita controle de alcadas de bloqueio e limite de credito? (default .F.)" })
		aadd(aListPar, { "ES_ALCCMP ", "L", ".F.", "Habilita controle de alcadas de valor maximo compensacao? (default .F.)" })
		aadd(aListPar, { "ES_ALCSAQ ", "L", ".F.", "Habilita controle de alcadas de saque pos pago? (default .F.)" })
		aadd(aListPar, { "ES_ALCDCX ", "L", ".F.", "Habilita controle de alcadas de diferenca de caixa? (default .F.)" })
		aadd(aListPar, { "ES_ALCDTIT", "L", ".F.", "Habilita controle de alcadas de desconto sobre titulos? (default .F.)" })
		aadd(aListPar, { "ES_ALCLOG ", "L", ".T.", "Habilita controle de log nas alcadas (default .T.)" })
		aadd(aListPar, { "ES_ALCLID ", "L", ".F.", "Habilita controle de saldo de alçada limite de desconto (default .F.)" })
		aadd(aListPar, { "ES_ALCTRC ", "L", ".F.", "Habilita controle de alçada de troco (default .F.)" })
		aadd(aListPar, { "ES_IPTSS  ", "C", GetServerIP(), "Ip Servidor TSS (default GetServerIP())" })
		aadd(aListPar, { "ES_DBTSS  ", "C", "postgres/sigatss", "DBMS/Base de Dados do TSS (default postgres/sigatss)" })
		aadd(aListPar, { "ES_PORTTSS", "N", "7890", "Porta da base de dados do TSS (default 7890)" })
		aadd(aListPar, { "ES_NWLTTSS", "C", "", "Nro lote para notas recuperadas via monitor PDV (parametro criado pelo sistema)" })
		aadd(aListPar, { "ESP_MOTOR ", "C", "", "Motorista padrao para entrada de devolucao de cupom fiscal - complemento fiscal CD6 (default 986981)" })
		aadd(aListPar, { "ESP_TRANSP", "C", "", "Transportadora padrao para entrada de devolucao de cupom fiscal - complemento fiscal CD6 (default 000001)" })
		aadd(aListPar, { "ESP_VEICUL", "C", "", "Veiculo padrao para entrada de devolucao de cupom fiscal - complemento fiscal CD6 (default 1491)" })
		aadd(aListPar, { "TP_ACTBXTR", "L", ".T.", "Habilita funcionalidade de baixa trocada no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCHT ", "L", ".T.", "Habilita funcionalidade de cheque troco no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCMP ", "L", ".T.", "Habilita funcionalidade de compensação no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTNP  ", "L", ".T.", "Habilita funcionalidade de nota a prazo no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTDP  ", "L", ".T.", "Habilita funcionalidade de depósito no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTSQ  ", "L", ".T.", "Habilita funcionalidade de saque no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTVCR ", "L", ".T.", "Habilita funcionalidade de validação de limite de crédito no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTVLH ", "L", ".T.", "Habilita funcionalidade de vale haver no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTVLS ", "L", ".T.", "Habilita funcionalidade de vale serviço no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCF  ", "L", ".T.", "Habilita funcionalidade de carta frete no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCT  ", "L", ".T.", "Habilita funcionalidade de CTF no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTLCS ", "L", ".T.", "Habilita funcionalidade de limite de credito por segmento (default .F.)" })
		aadd(aListPar, { "TP_MYSEGLC", "C", "", "Define o codigo do segmento no PDV." })
		aadd(aListPar, { "TP_ACTORC ", "L", ".T.", "Habilita funcionalidade de imprimir e gravar orçamento no host superior (default .F.)" })
		aadd(aListPar, { "TP_ACESSTF", "L", ".F.", "Habilita validacao acesso opcao troca forma, conferencia caixa (default .F.)" })
		aadd(aListPar, { "TP_EXITSYS", "L", ".T.", "Habilita fechar sistema ao sair da tela do PDV." })
		aadd(aListPar, { "MV_XADMFID", "C", "", "Adm. Financeiras para mudança de forma cartão para outros na emissão na nota. (Pegaponto)" })
		aadd(aListPar, { "MV_XDTABAS", "C", ""+DtoS(Date())+"", "Data do ultimo envio de e-mail com status de abastecimentos (erro/pendentes)" })
		aadd(aListPar, { "MV_XHRABAS", "C", ""+Time()+"", "Hora do ultimo envio de e-mail com status de abastecimentos (erro/pendentes)" })
		aadd(aListPar, { "MV_XMNABAS", "N", "120", "Invervalo minimo em minutos para envio da análise de status de abastecimentos" })
		aadd(aListPar, { "MV_XCONDCF", "C", "001", "Condição de Pagamento para emitente de carta frete." })
		aadd(aListPar, { "MV_XUSRADM", "C", "", "Define usuarios administradores para acessar rotina Controle de Acessos." })
		aadd(aListPar, { "MV_XPE1300", "C", "TRETP012", "Nome do ExecBlock a ser executado para geração da movimentação diária de combustíveis no bloco SPED 1300." })
		aadd(aListPar, { "MV_XMONMIN", "N", "3600", "JOb Monitor PDV: desconsidera os ultimos X segundos para não interferir no processo do PDV." })
		aadd(aListPar, { "MV_XVLDDEV", "L", ".T.", "Habilita validação de nota autorizada na devolução (default .F.)" })
		aadd(aListPar, { "MV_XBCOCDV", "C", "", "Banco de Devoluções: banco + agencia + conta (A6_COD+A6_AGENCIA+A6_NUMCON)" })
		aadd(aListPar, { "MV_LJFISMS", "C", "&U_TPDVE005()", "Mensagem padrao para impressao no rodape do cupom" })
		aadd(aListPar, { "MV_XPROCON", "C", "PROCON MT - Av. Baltazar Navarros, N.567, Bairro Bandeirantes, Cuiabá-MT, CEP 78010-020. Tel: 151 ou (65)3613-2100", "Mensagens informativas do cupom fiscal: Procon" })
		aadd(aListPar, { "TP_CCESEXP", "C", "", "Define o centro de custo para transferencia estoque exposição." })
		aadd(aListPar, { "MV_XCRCLIP", "L", ".T.", "Habilita bloqueio de CREDITO para cliente padrão (default .F.)" })
		aadd(aListPar, { "MV_XFUNBOL", "C", "TRETR009", "Funcao para definir fonte impressao boleto, rotinas faturamento. Default (TRETR009)" })
		aadd(aListPar, { "TP_PSWVEND", "L", ".T.", "Habilita controle de caixa por Vendedor, com exigência de senha." })
		aadd(aListPar, { "TP_CPSWVEN", "C", "A3_SENHA", "Define o campo senha a ser utilizado no cadastro do vendedor." })
		aadd(aListPar, { "MV_XTPCRC ", "L", ".T.", "Habilita o uso rotinas CRC." })
		aadd(aListPar, { "MV_VLDDTAB", "L", ".T.", "Habilita validacao data do abastecimento, dia anterior" })
		aadd(aListPar, { "MV_DTUVABA", "C", "", "Ultima data validacao do abastecimento, dia anterior" })
		aadd(aListPar, { "ES_LOGCCX ", "L", ".T.", "Habilita gravaçao log na rotina conferencia de caixa." })
		aadd(aListPar, { "ESP_XAGLUT", "N", "0.5", "Aglutinar abastecimentos: divergência máxima para considerar que sejam consecutivos" })
		aadd(aListPar, { "MV_XGERENT", "L", ".F.", "Habilita filtro combobox da sangria e suprimento pelo campo A6_XGERENT." })
		aadd(aListPar, { "MV_CXLOJA ", "C", "", "Códigos dos Caixas Gerais (BANCO/AGENCIA/CONTA), separados por /." })
		aadd(aListPar, { "MV_XPECRC ", "C", "2", "Qual PE usar para CRC: 1-Sigaloja;2=TotvsPDV. O valor Default é 2." })
		aadd(aListPar, { "TP_MULTAFE", "L", ".F.", "Habilita aferição selecionando vários itens (Multi-Seleção)." })
		aadd(aListPar, { "MV_XQTQLMC", "N", "20", "Define a quantidade de tanques a ser considerado nas rotinas LMC (criar campos MIE_ESTIxx e MIE_VTAQxx)" })
		aadd(aListPar, { "MV_XBLQAI0", "L", ".F.", "Habilita bloqueio de venda na filial, olhando para tabela AI0 (campo AI0_XBLFIL)." })
		aadd(aListPar, { "MV_LJORCAM", "C", "", "Campo de busca pincipal para buscar orçamento no host superior." })
		aadd(aListPar, { "MV_LJORCAA", "C", "L1_CGCMOTO", "Campo de busca secundário para buscar orçamento no host superior." })
		aadd(aListPar, { "MRPC_CAIXA", "C", "", "Determina o codigo de cada ambiente no PDV, preencher parametro por filial." })
		aadd(aListPar, { "MV_XCARGVD", "C", "", "Lista de cargos de vendedores habilitados para para o PDV." })
		aadd(aListPar, { "MV_XBICMOV", "L", ".T.", "Lista bicos nos registros SPED 1350 (BOMBAS), apenas quando possuir movimentos?  (default .T.)" })
		aadd(aListPar, { "MV_XFTCONV", "L", ".F.", "Define se rotina fatura ira trabalhar em modo conveniencia (default .F.)" })
		aadd(aListPar, { "MV_XPARCPG", "L", ".T.", "Define se a quantidade de parcelas cartao credito será definida pela condição de pagamento. (default .T.)" })
		aadd(aListPar, { "MV_XAVINEX", "L", ".T.", "Avalia inconsistencias extrato, rotina de Conciliação Cartão? (default .T.)" })
		aadd(aListPar, { "TP_RIDENTF", "C", "", "Modelo de relatório por identifid (vendedor): O-Old/N-New" })
		aadd(aListPar, { "TP_FPGCONV", "C", "", "Formas de pagamento adicionais, tratadas como convênios (igual NP)" })
		aadd(aListPar, { "MV_LJADFLD", "C", "A1_LOJA/A1_EST/A1_MUN", "Permite acrescentar campos na grid da pesquisa de clientes do Totvs PDV." })
		aadd(aListPar, { "MV_XFPGFAT", "C", "NP/BOL/RP/CF/FT/CC/CCP/CD/CDP/DP/CT/CTF/NF/VLS/RE/REN/CN", "Define as formas/tipos de pagamentos disponiveis para Faturamento." })
		aadd(aListPar, { "TP_SSVIASA", "N", "0", "Define o numero de vias adicionais para sangria e suprimento TotvsPDV." })
		aadd(aListPar, { "MV_XMOTEXF", "L", ".F.", "Habilita log de exclusão de faturas." })
		aadd(aListPar, { "MV_XX5MEXF", "C", "Z5", "Id da Tabela SX5 de motivos de exclusão de faturas." })
		aadd(aListPar, { "MV_XPENFCE", "L", ".F.", "Habilita pergunta para NF-e, quando não comunicar com TSS RETAGUARDA: Não será possível emitir NF-e, deseja emitir NFC-e? (ambiente com TSS OFF-LINE)" })
		aadd(aListPar, { "MV_XURLTSS", "C", "", "URL do TSS ON-LINE - Ex.: http://192.168.1.246:8092" })
		aadd(aListPar, { "MV_XNGDESC", "L", ".T.", "Ativa negociação pelo valor de desconto: U25_DESPBA" })
		aadd(aListPar, { "MV_XATUPRC", "L", ".T.", "Tipo de negociação no Totvs PDV: DESCONTO (.F.) ou PREÇO UNITÁRIO (.T.)"})
		aadd(aListPar, { "MV_XIMPDNF", "L", ".F.", "Habilita pergunta de impressão de danfinha (default .F.)" })
		aadd(aListPar, { "MV_XINFVEN", "L", ".T.", "Habilita dados do vendedor no rodapé do cupom (default .F.)" })
		aadd(aListPar, { "MV_XSELADM", "L", ".T.", "Define se ao inves de selecionar OPERADORA + BANDEIRA (.F.), será selecionado ADM. FINANCEIRA (.T.) (default .F.)" })
		aadd(aListPar, { "MV_XIDTSA3", "L", ".F.", "Define se vai gravar o campo A3_RFID automaticamente (default .T.)" })
		aadd(aListPar, { "TP_BLQCANC", "L", ".F.", "Bloqueia cancelamento de NFC-e quando ambiente estiver em contingência ou sem protocolo? (default .F.)" })
		aadd(aListPar, { "TP_HCTRASQ", "L", ".T.", "Habilita controle de transação na rotina de saque/vale ? (default .T.)" })
		aadd(aListPar, { "TP_HFA330Q", "L", ".T.", "Habilita a manipulação de query na FINA330 - compensação de valores (PE FA330QRY) ? (default .T.)" })
		aadd(aListPar, { "MV_XCOMBUS", "C", "", "Grupos de produtos, separados por '/', que identificam operações com combustíveis. (Somente combustiveis: GASOLINA, ETANOL e DIESEL)" })
		aadd(aListPar, { "TP_DA4SOBR", "N", 0, "Define se na importação de placas, quando placa ja vinculada a cliente/grupo se: 0 - Perguntar/1 - Sobrescrever/2 - Pular." })
		aadd(aListPar, { "MV_XPERCGP", "N", 0.6, "Define o percentual para perdas e sobras no LMC." })
		aadd(aListPar, { "TP_ZERAUF2", "L", ".T.", "Zera o valor do cheque troco quando processa estorno? (default .T.)" })
		aadd(aListPar, { "TP_IMPAGLC", "L", ".T.", "Imprime o aglutinado de cartão por cliente (default .T.)" })
		aadd(aListPar, { "TP_DETTVEN", "L", ".T.", "Detalhamento de troco em dinheiro das vendas (default .T.)" })
		aadd(aListPar, { "TP_IMPOBSC", "L", ".T.", "Imprime o observações da conferência de caixa (default .T.)" })
		aadd(aListPar, { "TP_FCHABAS", "L", ".F.", "No fechamento de caixa, valida se possui abastecimentos pendêntes (default .F.)" })
		aadd(aListPar, { "TP_VLEMTCF", "L", ".F.", "Valida equivalência: cliente vs emitente de carta frete (default .F.)" })
		aadd(aListPar, { "TP_IMPAFER", "L", ".T.", "Habilita/Desabilita impressão do comprovante de aferição (default .T.) " })
		aadd(aListPar, { "MV_XCALVEN", "L", ".F.", "Calcula novo vencimento da fatura baseado na calculo: DATABASE + DIAS (E4_COND) (default .F.) " })
		aadd(aListPar, { "MV_XVALCON", "L", ".T.", "Valida se a condição dos titulos selecionados são iguais, quando MV_XCALVEN estiver ativo (default .T.) " })
		aadd(aListPar, { "MV_XSUGDTN", "L", ".F.", "Sugere data de nova data de vencimento no faturamento flexível (default .F.) " })
		aadd(aListPar, { "ES_CONFPEN", "L", ".F.", "Permite confirmar caixa com pendência financeira (default .F.)" })
		aadd(aListPar, { "MV_XVADTCX", "L", ".T.", "Valida a data base referente a data do SO e abertura de caixa (default .T.)" })
		aadd(aListPar, { "TP_VLCCANC", "L", ".F.", "Valida a permissão de acesso para cancelamento de cupom no PDV (default .F.)" })
		aadd(aListPar, { "MV_XQTMPDV", "N", 990, "Quantidade máxima de itens permitido no grid/cesta (default 990)" })
		aadd(aListPar, { "TP_VLIDENT", "L", ".F.", "Bloqueio abastecimento de outro frentista (default .F.)" })
		aadd(aListPar, { "TP_LOGCABS", "L", ".T.", "Habilita log conout de leitura de abastecimento (automacao centralpdv) (default .T.)" })
		aadd(aListPar, { "TP_LOGABAU", "L", ".F.", "Habilita log autocom de leitura de abastecimento (automacao centralpdv) (default .F.)" })
		aadd(aListPar, { "TP_AFMAXLT", "N", "1000", "Define o maximo de litros permitidos na operação Aferição no PDV." })
		aadd(aListPar, { "TP_IREQNM0", "C", "M0_NOME/M0_NOMECOM", "Define campos da SM0 a serem impressos na sessão Filiais Autorizadas - Impressão Requisição" })
		aadd(aListPar, { "MV_XIMPORC", "L", ".F.", "Inibir a impressao de orçamento de venda no PDV sem gravação." })
		aadd(aListPar, { "MV_TIPAFER", "N", "0", "Tipo operação Aferição: 0=Sem Nota Fiscal;1=Com Nota Fiscal" })
		aadd(aListPar, { "MV_TESAFER", "C", "", "Define a TES a utilziar cado tipo afericao seja com nota fiscal." })
		aadd(aListPar, { "MV_XRQCPAD", "L", ".F.", "Permite incluir requisição para consumidor padrão?" })
		aadd(aListPar, { "TP_PROFLEX", "L", ".F.", "Ativa integração com Promoflex?" })
		aadd(aListPar, { "MV_XURLPRO", "C", "", "Promoflex: URL da API." })
		aadd(aListPar, { "MV_XTKNPRO", "C", "", "Promoflex: token de autenticação com API." })
		aadd(aListPar, { "MV_XCANPRO", "C", "", "Promoflex: path cancelameneto de venda." })
		aadd(aListPar, { "MV_XPOSPRO", "C", "", "Promoflex: path envio pós de venda." })
		aadd(aListPar, { "MV_XCODPRO", "C", "", "Promoflex: path de validar codigo e consulta descontos" })
		aadd(aListPar, { "MV_XALCCLB", "L", ".F.", "Habilita liberação de alçadas por código de liberação (default .F.)" })
		aadd(aListPar, { "TP_CHTCMC7", "L", ".F.", "Define se obriga a seleção do cheque troco por CMC7 (default .F.)" })
		aadd(aListPar, { "MV_XCHTROP", "L", ".F.", "Habilita Controle de Cheque Troco por Operador (default .F.)" })
		aadd(aListPar, { "TP_STATTSS", "L", ".F.", "Habilita menu com parametros e status do TSS (default .F.)" })
		aadd(aListPar, { "TP_PVVLFIN", "L", ".F.", "Define se bloqueia tela do vendedor, após cada venda (controle de caixa por Vendedor)" })
		aadd(aListPar, { "MV_XPLARET", "L", ".F.", "Habilita busca de placa na retaguarda." })
		aadd(aListPar, { "PPI_TABSPE", "N", "30", "Portal Posto: tempo de refresh de abastecimentos, em segundos." })
		aadd(aListPar, { "MV_XTABAST", "N", "0", "Portal Posto: tempo em minutos para destacar abastecimentos pendentes: default 2 hora" })
		aadd(aListPar, { "PPI_WSPOST", "C", "", "Portal Posto: URL do host de leitura abastecimentos" })
		aadd(aListPar, { "PPI_TCARGA", "N", "60", "Portal Posto: definir o tempo de refresh de cargas, em segundos" })
		aadd(aListPar, { "MV_XRMQIP ", "C", "", "Carga RabbitMQ: Ip de conexao." })
		aadd(aListPar, { "MV_XRMQPOR", "N", "5672", "Carga RabbitMQ: Porta de conexao" })
		aadd(aListPar, { "MV_XRMQUSE", "c", "", "Carga RabbitMQ: Usuario de conexao" })
		aadd(aListPar, { "MV_XRMQPSW", "c", "", "Carga RabbitMQ: Senha de conexao" })
		aadd(aListPar, { "MV_XRMQCHA", "N", "1", "Carga RabbitMQ: Channel ID de conexao" })
		aadd(aListPar, { "MV_XRMQEXC", "C", "", "Carga RabbitMQ: Nome da Exchange " })
		aadd(aListPar, { "MV_XREDEND", "C", "", "Carga Redis: Ip de conexao." })
		aadd(aListPar, { "MV_XREDPOR", "N", "5672", "Carga Redis: Porta de conexao" })
		aadd(aListPar, { "MV_XREDAUT", "C", "", "Carga Redis: Senha de conexao" })
		aadd(aListPar, { "MV_XREDLPD", "C", "", "Carga Redis: Chave de tamanho 14: AAAAMMDDHHMMSS" })
		aadd(aListPar, { "TP_AJE1EXT", "L", ".F.", "Define se ajusta campos NSU e DOC da SE1 conforme extrato" })
		aadd(aListPar, { "MV_XCTRSAC", "L", ".F.", "define se irá sugerir troca de sacado durante a importação do extrato" })
		aadd(aListPar, { "MV_XCONFAC", "L", ".F.", "Habilita controle de acesso a rotina conferencia de caixa." })
		aadd(aListPar, { "TP_XNFACPA", "L", ".T.", "Define se poderá emitir nota sobre cupom de consumidor padrao" })
		aadd(aListPar, { "MV_XLMCKAR", "L", ".F.", "habilita ajuste perda ou ganho pelo kardex" })
		aadd(aListPar, { "MV_XLMCLKA", "N", "0", "limite em litros para diferença do kardex e estoque escritural" })
		aadd(aListPar, { "MV_XLOGFAT", "L", ".F.", "habilita gravacao de log ao gerar faturas" })
		aadd(aListPar, { "MV_XMOTREN", "L", ".F.", "habilita log renegociação de faturas" })
		aadd(aListPar, { "MV_XTXACES", "L", ".F.", "habilita uso de valores acessórios para taxas de cartão" })
		aadd(aListPar, { "MV_XLMCTQS", "L", ".F.", "Usa campo TQI_TQSPED tanque sped para impressao LMC?" })
		aadd(aListPar, { "TP_CMPCPAD", "L", ".F.", "Habilita compensação para cliente padrão" })


	Case cRot == "002" // Preços em Níveis

		// Lista dos parametros encontrados no projeto tpdvposto
		cParamet += "MV_XNIVCBC/MV_XTABNV0/MV_XTABNV1/MV_XTABNV2/MV_LJCNVDA/MV_TABPAD /MV_XPDFTAB/" // 7

		// lista de parametros com valores defaults
		// aListPar -> [nome], [tipo], [conteudo], [descricao] (150 caracteres)
		aadd(aListPar, { "MV_XNIVCBC", "L", ".F.", "Ativar/desativar uso de preços em níveis na itegraçao CBC ? (default .F.)" })
		aadd(aListPar, { "MV_XTABNV0", "C", "001", "Definir a tabela de preços utilizada para preço nível 0 (zero), Dinheiro." })
		aadd(aListPar, { "MV_XTABNV1", "C", "001", "Definir a tabela de preços utilizada para preço nível 1 (um), Débito." })
		aadd(aListPar, { "MV_XTABNV2", "C", "001", "Definir a tabela de preços utilizada para preço nível 2 (dois), Crédito." })
		aadd(aListPar, { "MV_XPDFTAB", "L", ".F.", "Permite baixa de abastecimento cujo o preço de bomba é diferente do preço de tabela ? (default .F.)"})
	
	Case cRot == "003" // Naturezas Financeiras

		cParamet += "MV_NATCART/MV_NATCHEQ/MV_NATCONV/MV_NATCRED/MV_NATDINH/MV_NATFIN /MV_NATOUTR/MV_NATTEF /MV_NATTROC/MV_NATVALE"
		cParamet += "MV_XCNATCC/MV_XCNATCD/MV_XCNATCF/MV_XCNATCH/MV_XCNATCT/MV_XCNATDI/TP_NATNP  /TP_NATCF  /TP_NATCT  /"
		cParamet += "MV_XNATCHA/MV_XNATFAL/MV_XNATFAT/MV_XCNATVL/"
		cParamet += "MV_XNATFUN/MV_XNATNCC/MV_XNATNDC/MV_XNATRA /MV_XNATRPS/MV_XNATTNC/MV_XNATVSO/MV_XNATVSP/MV_XNATVSR/MV_XNATVST/"

	Case cRot == "004" // Larco

		cParamet += "MV_VLDDTAB/MV_DTUVABA/TP_BLQCANC/MV_LJTPCAN/TP_FCHABAS/TP_VLCCANC/MV_XVADTCX/MV_ESPECIE"

		aadd(aListPar, { "MV_XVADTCX", "L", ".T.", "Valida a data base referente a data do SO e abertura de caixa (default .T.)" })
		aadd(aListPar, { "TP_VLCCANC", "L", ".F.", "Valida a permissão de acesso para cancelamento de cupom no PDV (default .F.)" })
		aadd(aListPar, { "TP_FCHABAS", "L", ".F.", "No fechamento de caixa, valida se possui abastecimentos pendêntes (default .F.)" })
		aadd(aListPar, { "TP_BLQCANC", "L", ".F.", "Bloqueia cancelamento de NFC-e quando ambiente estiver em contingência ou sem protocolo? (default .F.)" })
		aadd(aListPar, { "MV_VLDDTAB", "L", ".T.", "Habilita validacao data do abastecimento, dia anterior" })
		aadd(aListPar, { "MV_DTUVABA", "C", "", "Ultima data validacao do abastecimento, dia anterior" })

	Case cRot == "005" // Parâmetros de Implantação

		cParamet += "MV_LJCNVDA/MV_TABPAD/MV_CONDPAD/MV_LJCONFF/MV_LJOBGCF/MV_LJFECCX/MV_LJOFFLN/MV_LJPDVEN/MV_COMBUS/MV_LJDCCLI/MV_LJTROCO/MV_LJFISMS/MV_USACRED/"
		cParamet += "MV_LJCPNCC/MV_LJTPCAN/MV_LJTEF20/MV_TELAFIN/MV_EMPTEF/MV_ESPECIE/MV_LOJANF/MV_SERIE/MV_FISNOTA/MV_LJTXNFE/MV_LJTNINT/
		cParamet += "MV_NFCEURL/MV_SPEDURL/MV_CLIPAD/MV_LOJAPAD/MV_LJPOSTO"

		aadd(aListPar, { "MV_CONDPAD", "C", " "  , "Condicao de Pagamento Padrao." })
		aadd(aListPar, { "MV_LJPOSTO", "L", ".T.", "Habilita Posto de Combustível no Totvs PDV." })
		aadd(aListPar, { "MV_XPOSTO ", "L", ".T.", "Habilita Posto de Combustível (Posto Inteligente)." })
		aadd(aListPar, { "MV_XSRVPDV", "L", ".T.", "Servidor PDV ou base Totvs PDV ? (default .T.)" })
		aadd(aListPar, { "MV_LJCONFF", "L", ".F.", "Determina se a conf.de caixa será executada no fecham.de caixa." })
		aadd(aListPar, { "MV_LJOBGCF", "L", ".F.", "Indica se é obrigatório confirmar a Conferência de Caixa, para abertura no PDV" })
		aadd(aListPar, { "MV_LJPDVEN", "L", ".T.", "Altera o vendedor na venda do Totvs PDV" })
		aadd(aListPar, { "TP_EXITSYS", "L", ".F.", "Habilita fechar sistema ao sair da tela do PDV." })
		aadd(aListPar, { "MV_VLDDTAB", "L", ".T.", "Habilita validacao data do abastecimento, dia anterior" })
		aadd(aListPar, { "MV_DTUVABA", "C", "", "Ultima data validacao do abastecimento, dia anterior" })
		aadd(aListPar, { "MV_XNGDESC", "L", ".T.", "Ativa negociação pelo valor de desconto: U25_DESPBA" })
		aadd(aListPar, { "MV_XATUPRC", "L", ".T.", "Tipo de negociação no Totvs PDV: DESCONTO (.F.) ou PREÇO UNITÁRIO (.T.)"})
		aadd(aListPar, { "TP_ACTCF  ", "L", ".T.", "Habilita funcionalidade de carta frete no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTNP  ", "L", ".T.", "Habilita funcionalidade de nota a prazo no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTBXTR", "L", ".T.", "Habilita funcionalidade de baixa trocada no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCHT ", "L", ".T.", "Habilita funcionalidade de cheque troco no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCMP ", "L", ".T.", "Habilita funcionalidade de compensação no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTDP  ", "L", ".T.", "Habilita funcionalidade de depósito no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTSQ  ", "L", ".T.", "Habilita funcionalidade de saque no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTVCR ", "L", ".T.", "Habilita funcionalidade de validação de limite de crédito no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTVLH ", "L", ".T.", "Habilita funcionalidade de vale haver no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTVLS ", "L", ".T.", "Habilita funcionalidade de vale serviço no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTCT  ", "L", ".T.", "Habilita funcionalidade de CTF no PDV (default .F.)" })
		aadd(aListPar, { "TP_ACTLCS ", "L", ".T.", "Habilita funcionalidade de limite de credito por segmento (default .F.)" })
		aadd(aListPar, { "TP_ACTORC ", "L", ".T.", "Habilita funcionalidade de imprimir e gravar orçamento no host superior (default .F.)" })
		aadd(aListPar, { "MV_LJDCCLI", "N", "3"  , "Define em qual momento a tela de documento de Identificaçao (CPF/CNPJ) 0-Legislaçao;1-Inicio;2-Final;3-Ambos" })
		aadd(aListPar, { "MV_LJTROCO", "L", ".T.", "Determina se utiliza troco para diferentes formas de pagamento" })
		aadd(aListPar, { "MV_XCOMBUS", "C", "", "Grupos de produtos, separados por '/', que identificam operações com combustíveis. (Somente combustiveis: GASOLINA, ETANOL e DIESEL)" })
		aadd(aListPar, { "MV_XGRARLA", "C", " ", "Mensagem para o Arla" })
		aadd(aListPar, { "MV_LJFISMS", "C", "&U_TPDVE005()", "Mensagem padrao para impressao no rodape do cupom" })
		aadd(aListPar, { "MV_XINCSLI", "L", ".T.", "Ativa replica para preencher SLI (ambiente PDV)" })
		aadd(aListPar, { "MV_XINFVEN", "L", ".T.", "Habilita dados do vendedor no rodapé do cupom (default .F.)" })
		aadd(aListPar, { "MV_XSELADM", "L", ".T.", "Define se ao inves de selecionar OPERADORA + BANDEIRA (.F.), será selecionado ADM. FINANCEIRA (.T.) (default .F.)" })
		aadd(aListPar, { "MV_XCONDCF", "C", "001", "Condição de Pagamento para emitente de carta frete." })
		aadd(aListPar, { "MV_NFCEGC" , "L", ".T.", " Indica se o Grupo de Cartões<card> será adicionada ao grupo YA.Formas de Pagamento no arquivo eletrônico da NFC-e." })
		aadd(aListPar, { "MV_USACRED", "C", "NN", "A primeira posição indica se gera NCC para trocas por valor menor ( S ou N). E a segunda posição indica se utiliza NCC para pagamento na Venda." })
		aadd(aListPar, { "MV_LJCPNCC", "N", "4", "Compensação de NCC quando a utilização for parcial" })
		aadd(aListPar, { "TP_AFMAXLT", "N", "1000", "Define o maximo de litros permitidos na operação Aferição no PDV." })
		aadd(aListPar, { "TP_CHTCMC7", "L", ".F.", "Define se obriga a seleção do cheque troco por CMC7 (default .F.)" })
		aadd(aListPar, { "MV_LJTPCAN", "N", "2", "1 = Legado, 2 = Cancelamento preferencialmente Online com possibilidade de cancelamento Offline" })
		aadd(aListPar, { "MV_FISNOTA", "L", ".T.", "Define se Utiliza a pergunta - Imprime Cupom Fiscal , Onde o usuário poderá imprimir uma nota fiscal, desde que não seja um usuário fiscal" })
		aadd(aListPar, { "MV_LJTXNFE", "N", "3", "Habilita a transmissão da NF-e no SIGALOJA. Onde:0-Desabilitado, 1-Transmissão da NF-e 2- Transm NF-e and print DANFE" })
		aadd(aListPar, { "MV_LJTNINT", "C", "20;5", "Indica o nro de tentativas de consulta ao TSS e o intervalo (em segundos) entre elas. Usado na obtenção do retorno da NFe transmitida pelo SIGALOJA" })
		aadd(aListPar, { "TP_CMPCPAD", "L", ".F.", "Habilita compensação para cliente padrão" })
		aadd(aListPar, { "MV_NFCEURL", "C", "http://localhost:8080", "URL de comunicação com o TSS para Transmitir NFC-e" })
		aadd(aListPar, { "MV_SPEDURL", "C", "http://localhost:8080", "URL de comunicação com o TSS para Transmitir NF-e" })
		aadd(aListPar, { "MV_XRMQIP ", "C", "", "Carga RabbitMQ: Ip de conexao." })
		aadd(aListPar, { "MV_XRMQPOR", "N", "5672", "Carga RabbitMQ: Porta de conexao" })
		aadd(aListPar, { "MV_XRMQUSE", "C", "", "Carga RabbitMQ: Usuario de conexao" })
		aadd(aListPar, { "MV_XRMQPSW", "C", "", "Carga RabbitMQ: Senha de conexao" })
		aadd(aListPar, { "MV_XRMQCHA", "N", "1", "Carga RabbitMQ: Channel ID de conexao" })
		aadd(aListPar, { "MV_XRMQEXC", "C", "", "Carga RabbitMQ: Nome da Exchange " })
		aadd(aListPar, { "TP_FPGCONV", "C", "", "Formas de pagamento adicionais, tratadas como convênios (igual NP)" })
		aadd(aListPar, { "ES_ALCADA ", "L", ".F.", "Habilita controle de alcadas ? (default .F.)" })
		aadd(aListPar, { "ES_ALCDES ", "L", ".F.", "Habilita controle de alcadas de desconto? (default .F.)" })
		aadd(aListPar, { "ES_ALCDPN ", "L", ".F.", "Habilita controle de alcadas de desconto sobre preço negociado? (default .F.)" })
		aadd(aListPar, { "ES_ALCLIM ", "L", ".F.", "Habilita controle de alcadas de bloqueio e limite de credito? (default .F.)" })
		aadd(aListPar, { "ES_ALCCMP ", "L", ".F.", "Habilita controle de alcadas de valor maximo compensacao? (default .F.)" })
		aadd(aListPar, { "ES_ALCSAQ ", "L", ".F.", "Habilita controle de alcadas de saque pos pago? (default .F.)" })
		aadd(aListPar, { "ES_ALCDCX ", "L", ".F.", "Habilita controle de alcadas de diferenca de caixa? (default .F.)" })
		aadd(aListPar, { "ES_ALCDTIT", "L", ".F.", "Habilita controle de alcadas de desconto sobre titulos? (default .F.)" })
		aadd(aListPar, { "ES_ALCLOG ", "L", ".T.", "Habilita controle de log nas alcadas (default .T.)" })
		aadd(aListPar, { "ES_ALCLID ", "L", ".F.", "Habilita controle de saldo de alçada limite de desconto (default .F.)" })
		aadd(aListPar, { "ES_ALCTRC ", "L", ".F.", "Habilita controle de alçada de troco (default .F.)" })
		
		


	End Case

	aParamet := StrTokArr2(cParamet, "/", .T.)
	For ni := 1 to Len(aParamet)
		If !Empty(aParamet[ni]) .and. aScan( aListPar, { |x| x[1] == aParamet[ni] } ) <= 0
			aadd(aListPar, {aParamet[ni],"","",""})
		EndIf
	Next ni

	For ni := 1 to len(aListPar)
		If Eval(bGetMvFil,aListPar[ni][1],.T.,)
			aAdd(aVetPar,{ "overd", aListPar[ni][1], (cAliasSX6)->&("X6_TIPO"), Alltrim(X6Conteud()), Alltrim(X6Descric())+" "+Alltrim(X6Desc1())+" "+Alltrim(X6Desc2()) })
		Else
			aAdd(aVetPar,{ "overm", aListPar[ni][1], aListPar[ni][2], aListPar[ni][3], Alltrim(aListPar[ni][4]) })
		EndIf
	Next ni

	If len(aVetPar) <= 0
		aAdd(aVetPar,{"overm","","","",""})
	EndIf
	Asort(aVetPar,,,{|x,y| x[2] < y[2] }) //ordem crescente

	If lRefr
		oLbPar:nAt := 1
		oLbPar:SetArray(aVetPar)
		oLbPar:bLine := { || { &(aVetPar[oLbPar:nAt,1]) , aVetPar[oLbPar:nAt,2] , aVetPar[oLbPar:nAt,3] , 	aVetPar[oLbPar:nAt,4] , aVetPar[oLbPar:nAt,5] }}
		oLbPar:Refresh()
	EndIf

Return()

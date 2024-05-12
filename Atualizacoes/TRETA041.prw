#INCLUDE "PROTHEUS.CH"
#INCLUDE "hbutton.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"
#INCLUDE "MSGRAPHI.CH"
#INCLUDE "fileio.ch"
#INCLUDE 'parmtype.ch'
#INCLUDE 'poscss.ch'
#INCLUDE 'rwmake.ch'

Static cSGBD	:= AllTrim(Upper(TcGetDb()))	// -- Banco de dados atulizado (Para embientes TOP) 			 	

/*/{Protheus.doc} TRETA041
Rotina de histórico de consumo e limite de crédito.

@author Wellington Gonçalves
@since 31/07/2015
@version 1.0

@return ${return}, ${return_description}

@param lPDV, logical, tela do pdv
@param cAmbiente, characters, ambiente
@param cTipo, characters, tipo
@param cGrupo, characters, grupo de cliente
@param cCliente, characters, cliente
@param cLoja, characters, loja
@param cMotorista, characters, motorista
@param cPlaca, characters, placa

@type function
/*/
User Function TRETA041(lPDV,cAmbiente,cTipo,cGrupo,cCliente,cLoja,cMotorista,cPlaca)

	Local lContinua		:= .T.
	Local lPergunta		:= .T.
	Local cPerspectiva	:= "" // GRUPO , CLIENTE , MOTORISTA , PLACA
	Local aFiliais		:= {}
	Local lSrvPDV 		:= SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV

	Default cTipo		:= "2" // 1=Sintetico;2=Analitico
	Default cGrupo		:= ""
	Default cCliente	:= ""
	Default cLoja		:= ""
	Default cMotorista	:= ""
	Default cPlaca		:= ""
	Default lPDV   		:= .F.

	If !lSrvPDV
		Default cAmbiente	:= "1" // 1=Retaguarda
	Else
		Default cAmbiente	:= "2" // 2=PDV
	EndIf

// enquanto o usuário não clicar em cancelar para fechar a tela
	While lContinua

		if !lPDV // se for chamdo fora da tela do pdv

			if lPergunta // se ainda não foram informados os parâmetros

				if U_TRETA41C(@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca) // se o usuário confimou a tela

					if Empty(cGrupo) .AND. ( Empty(cCliente) .OR. Empty(cLoja)  ) .AND. Empty(cMotorista) .AND. Empty(cPlaca) // se o usuário não preencheu nenhum parâmetro
						Alert("Informe pelo menos uma entidade!")
						Loop
						//else
						//lPergunta := .F. // para não mostrar a tela de perguntas novamente
					endif

				else // se o usuário fechou a tela
					Exit
				endif

			endif

		endif

		// chamo a tela de histórico de vendas
		MsAguarde( {|| RunTela(@lContinua,@cTipo,cAmbiente,@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca,@cPerspectiva,@aFiliais,@lPergunta)}, "Aguarde", "Consultando registros...", .F. )

	EndDo

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ RunTela º Autor ³ Wellington Gonçalves º Data ³ 18/09/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Fução que monta a tela								      º±±
±±º          ³ 								                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Parâmetro por referência que termina o processamento   º±±
±±º          ³ 2 - Tipo de visualização: 1=Sintetico;2=Analitico		  º±±
±±º          ³ 3 - Ambiente de visualização: 1=Retaguarda;2=Posto		  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function RunTela(lContinua,cTipo,cAmbiente,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais,lPergunta)

	Local oBtnClose
	Local oGetGrupo
	Local oGetCliente
	Local oGetMotorista
	Local oGetPlaca
	Local oFonteSay			:= TFont():New("Verdana",,022,,.F.,,,,,.F.,.F.)
	Local oFonteSaySub		:= TFont():New("Verdana",,022,,.T.,,,,,.T.,.F.)
	Local oFonteGet			:= TFont():New("Verdana",,014,,.F.,,,,,.F.,.F.)

	Local aResolucao		:= MsAdvSize()
	Local nLargura			:= aResolucao[5]
	Local nAltura			:= aResolucao[6]
	Local aPanels	   		:= Array(6)
	Local cGetGrupo			:= Posicione("ACY",1,xFilial("ACY") + cGrupo,"ACY_DESCRI")
	Local cGetCliente		:= iif(!Empty(cCliente), Posicione("SA1",1,xFilial("SA1") + cCliente + cLoja,"A1_NOME"), )
	Local cGetMotorista		:= Posicione("DA4",3,xFilial("DA4") + cMotorista,"DA4_NOME")
	Local cGetPlaca			:= cPlaca
	Local aHistVenda		:= {}
	Local aHistCredito		:= {}
	Local aPrecos			:= {}
	Local oPanel1

	Private aStatusMenu		:= {} //[01] - MSPAINEL BOTÃO / [02] - PAINEL MARCA RODAPE BOTÃO

	Static oDlgHistorico
	Static oPanelVenda
	Static oPanelCred
	Static oPanelPrecos
	Static oPanelConfig

// Laoyt do Dialog
/////////////////////////////////////////////////////////////////////////////////////////////
//                              PANEL 1 (UTILIZADO PARA BORDA)                             //
//  /////////////////////////////////////////////////////////////////////////////////////  //
//  //								  PANEL 2 (GLOBAL)					   			   //  //
//  //	////////////////////////////////////////////////////////////////////////////   //  //
//  //	// 							  PANEL 3 (MENUS)		// PANEL 4 (BTN CLOSE)//   //  //
//  //	////////////////////////////////////////////////////////////////////////////   //  //
//  //	// 							PANEL 5 (ENTIDADES)							  //   //  //
//  //	////////////////////////////////////////////////////////////////////////////   //  //
//  //	// 																		  //   //  //
//  //	// 																		  //   //  //
//  //	// 																		  //   //  //
//  //	// 						  PANEL 6 (AREA DE TRABALHO)					  //   //  //
//  //	// 																		  //   //  //
//  //	// 																		  //   //  //
//  //	// 																		  //   //  //
//  //	// 																		  //   //  //
//  //	// 																		  //   //  //
//  //	////////////////////////////////////////////////////////////////////////////   //  //
//  //																				   //  //
//  /////////////////////////////////////////////////////////////////////////////////////  //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

	aPanels[01] := { 000 				, 000 					, nLargura / 2 + 4 	, nAltura / 2 + 14 								}	// PANEL 1
	aPanels[02] := { aPanels[1,1] + 3	, aPanels[1,2] + 3		, aPanels[1,3] - 6	, aPanels[1,4] - 6 								}	// PANEL 2
	aPanels[03] := { 000  				, 000 	   	   			, aPanels[2,3] - 25	, 25 											}	// PANEL 3
	aPanels[04] := { aPanels[3,2]		, aPanels[3,3] 	   		, aPanels[3,3] + 25	, 25 											}	// PANEL 4
	aPanels[05] := { aPanels[3,1] + 25	, aPanels[3,2] 		 	, aPanels[2,3]		, 30 		   									}	// PANEL 5
	aPanels[06] := { aPanels[5,1] + 30	, aPanels[5,2] 		 	, aPanels[2,3]		, aPanels[2,4] - aPanels[4,4] - aPanels[5,4]  	}	// PANEL 6

// atribui o default da variável
	lPergunta := .T.

// se a perspectiva não está preenchida pego a primeira entidade preenchida
	if Empty(cPerspectiva)

		if !Empty(cGetGrupo)
			cPerspectiva := "GRUPO"
		elseif !Empty(cGetCliente)
			cPerspectiva := "CLIENTE"
		elseif !Empty(cGetMotorista)
			cPerspectiva := "MOTORISTA"
		elseif !Empty(cGetPlaca)
			cPerspectiva := "PLACA"
		endif

	endif

// função que busca os dados para visualização
	BuscaDados(cAmbiente,aHistVenda,aHistCredito,aPrecos,@aFiliais,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva)

	DEFINE MSDIALOG oDlgHistorico TITLE "Histórico de Consumo e Crédito" FROM 000, 000  TO nAltura, nLargura PIXEL OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)

	@ aPanels[1,1], aPanels[1,2] MSPANEL oPanel1 SIZE aPanels[1,3], aPanels[1,4] OF oDlgHistorico RAISED // borda da tela
	@ aPanels[2,1], aPanels[2,2] MSPANEL oPanel2 SIZE aPanels[2,3], aPanels[2,4] OF oPanel1 // painel principal
	@ aPanels[3,1], aPanels[3,2] MSPANEL oPanel3 SIZE aPanels[3,3], aPanels[3,4] OF oPanel2 // menu de botões
	@ aPanels[4,1], aPanels[4,2] MSPANEL oPanel4 SIZE aPanels[4,3], aPanels[4,4] OF oPanel2 RAISED // botão fechar
	@ aPanels[5,1], aPanels[5,2] MSPANEL oPanel5 SIZE aPanels[5,3], aPanels[5,4] OF oPanel2 // seleçao de entidade
	@ aPanels[6,1], aPanels[6,2] MSPANEL oPanel6 SIZE aPanels[6,3], aPanels[6,4] OF oPanel2 // tela de dados

// função que cria a barra de menus
	UPanelMenu(oPanel3,cPerspectiva)

// botão fechar
//oBtnClose := TBTNPDV():New(006,006,27/2,23/2,oPanel4,"PCLXVERM.png", {|| IIF(cAmbiente == "2",lContinua := .F.,), oDlgHistorico:End()}, "Fechar")
	oBtnClose := TButton():New( 006,;
		006,;
		"X",;
		oPanel4,;
		{|| IIF(cAmbiente == "2",lContinua := .F.,), oDlgHistorico:End()},;
		27/2,;
		23/2,;
		,,,.T.,;
		,,,{|| .T.})
	oBtnClose:SetCSS( POSCSS (GetClassName(oBtnClose), CSS_BTN_FOCAL ))

	@ 008, 005 SAY oSay1 PROMPT "Grupo:" SIZE 050, 015 OF oPanel5 FONT iif( cPerspectiva == "GRUPO" , oFonteSaySub , oFonteSay ) PIXEL
	@ 005, 040 MSGET oGetGrupo VAR cGetGrupo SIZE 070, 018 OF oPanel5 FONT oFonteGet PIXEL WHEN .F.

	oSay1:BLCLICKED := {|| ( iif( Empty(cGetGrupo) ,;
		iif(!Empty(cGrupo := Posicione("SA1",1,xFilial("SA1")+cCliente+cLoja,"A1_GRPVEN")), (lPergunta := .F., cCliente := "", cLoja := "", cPerspectiva := "GRUPO" , oDlgHistorico:End()), ),;
		) )}

	@ 008, 120 SAY oSay2 PROMPT "Cliente:" SIZE 050, 015 OF oPanel5 FONT iif( cPerspectiva == "CLIENTE" , oFonteSaySub , oFonteSay ) PIXEL
	@ 005, 160 MSGET oGetCliente VAR cGetCliente SIZE 070, 018 OF oPanel5 COLORS 0, 16777215 FONT oFonteGet PIXEL WHEN .F.

//oSay2:BLCLICKED := {|| ( iif( Empty(cGetCliente) ,, (cPerspectiva := "CLIENTE" , oDlgHistorico:End()) ) )}
	oSay2:BLCLICKED := {|| iif(U_TRETA41C(@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca),(lPergunta := .F., cPerspectiva := "CLIENTE", oDlgHistorico:End()) , )}

	@ 008, 240 SAY oSay3 PROMPT "Motorista:" SIZE 050, 015 OF oPanel5 FONT iif( cPerspectiva == "MOTORISTA" , oFonteSaySub , oFonteSay ) PIXEL
	@ 005, 290 MSGET oGetMotorista VAR cGetMotorista SIZE 070, 018 OF oPanel5 COLORS 0, 16777215 FONT oFonteGet PIXEL WHEN .F.

	oSay3:BLCLICKED := {|| ( iif( Empty(cGetMotorista) ,, (cPerspectiva := "MOTORISTA" , oDlgHistorico:End()) ) )}

	@ 008, 370 SAY oSay4 PROMPT "Placa:" SIZE 050, 015 OF oPanel5 FONT iif( cPerspectiva == "PLACA" , oFonteSaySub , oFonteSay ) PIXEL
	@ 005, 403 MSGET oGetPlaca VAR cGetPlaca SIZE 070, 018 OF oPanel5 PICTURE "@!R NNN-9N99" COLORS 0, 16777215 FONT oFonteGet PIXEL WHEN .F.

	oSay4:BLCLICKED := {|| ( iif( Empty(cGetPlaca) ,, (cPerspectiva := "PLACA" , oDlgHistorico:End()) ) )}

// função que atualiza o status dos menus
	UMenuStatus(1)

// crio o painel de histórico de vendas
	oPanelVenda := UHistVend(cTipo,oPanel6,aHistVenda,cPerspectiva,cCliente,cLoja)
	oPanelVenda:Show()

// crio o painel de historico de crédito
	oPanelCred := UHistCred(cTipo,oPanel6,aHistCredito)
	oPanelCred:Hide()

// crio o painel de precos
	oPanelPrecos := UPrecos(oPanel6,aPrecos)
	oPanelPrecos:Hide()

// crio o painel de configurações
	oPanelConfig := UConfig(oPanel6,@cTipo,aFiliais,@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca,@cPerspectiva,@lPergunta)
	oPanelConfig:Hide()

	ACTIVATE MSDIALOG oDlgHistorico CENTERED

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UPanelMenu ºAutor³ Wellington Gonçalves ºData ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o painel da barra de menus			      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel de menus que irá receber os botões    º±±
±±		     ³ 2 - Objeto do painel de dados							  º±±
±±		     ³ 3 - Tipo de visão: 1=Sintetico;2=Analitico				  º±±
±±		     ³ 4 - Opcao de visualizacao								  º±±
±±		     ³ 5 - Array com o status dos menus							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UPanelMenu(oPanelMenu,cPerspectiva)

	Local oFnt1 		:= TFont():New("Verdana",,016,,.T.,,,,,.F.,.F.)
	Local nCorPnl		:= 6118749
	Local aMenus		:= {}
	Local cBlExec		:= ""
	Local nPanelHeight	:= oPanelMenu:nClientHeight / 2
	Local nPanelWidth	:= oPanelMenu:nClientWidth / 2
	Local nY			:= 0
	Local nX			:= 0

	aadd(aMenus,{"Histórico de Vendas"	, " ( UPanelDados(1,cPerspectiva), UMenuStatus(1) ) "})
	aadd(aMenus,{"Histórico de Crédito"	, " iif(cPerspectiva == 'GRUPO' .OR. cPerspectiva == 'CLIENTE' , ( UPanelDados(2,cPerspectiva), UMenuStatus(2) ) , NIL ) "})
	aadd(aMenus,{"Preços"				, " iif(cPerspectiva == 'GRUPO' .OR. cPerspectiva == 'CLIENTE' , ( UPanelDados(3,cPerspectiva), UMenuStatus(3) ) , NIL ) "})
	aadd(aMenus,{"Configurações"		, " ( UPanelDados(4,cPerspectiva), UMenuStatus(4) ) "})

	nTamButtons := nPanelWidth / Len(aMenus)

	For nX := 1 To Len(aMenus)

		// crio o panel do botao
		@ 000, nY MSPANEL &("oBtnBar" + cValToChar(nX)) PROMPT aMenus[nX,1] SIZE nTamButtons, nPanelHeight OF oPanelMenu COLORS 16777215, nCorPnl CENTERED RAISED

		// crio o panel com a marcação da seleção
		@ nPanelHeight - 005, 005 MSPANEL &("oMarkBar" + cValToChar(nX)) PROMPT "" SIZE nTamButtons - 10, 002 OF &("oBtnBar" + cValToChar(nX)) COLORS 0, 12632256 CENTERED RAISED

		// altero a fonte do texto do panel
		&("oBtnBar" + cValToChar(nX)):oFont := oFnt1

		// crio o bloco de códio com a função passada no ponto de entrada
		cBlExec := "{|| " + aMenus[nX,2] + "}"

		// atribuo o bloco de código a propriedade de clique no panel
		&("oBtnBar" + cValToChar(nX)):BLCLICKED := &cBlExec

		// alimento um array dos botões do menu para posteriormente atualizar a seleção dos mesmos
		aadd(aStatusMenu,{&("oBtnBar" + cValToChar(nX)),&("oMarkBar" + cValToChar(nX))})

		nY += (nTamButtons)

	Next nX

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UMenuStatusºAutor³ Wellington Gonçalves ºData ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que muda o status dos botões da barra de menus      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Opcao de visualizacao								  º±±
±±		     ³ 2 - Array com os botões									  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UMenuStatus(nOpcao)
	Local nX := 0

// faço um loop no status dos botões para atualizar o marcador
// aStatusMenu - [01] - MSPAINEL BOTÃO / [02] - MSPAINEL LINHA MARCAÇÃO RODAPÉ BOTÃO
	For nX := 1 To Len(aStatusMenu)

		if nOpcao == nX
			aStatusMenu[nX][02]:Hide()
			aStatusMenu[nX][02]:Show()
			aStatusMenu[nX][01]:Refresh()
			aStatusMenu[nX][02]:Refresh()

		else
			aStatusMenu[nX][02]:Hide()

		endif

	Next nX

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UPanelDados ºAutor³Wellington Gonçalves ºData ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o painel dos dados					      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel de dados							  º±±
±±		     ³ 2 - Tipo de visão: 1=Sintetico;2=Analitico				  º±±
±±		     ³ 3 - Opcao de visualizacao								  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UPanelDados(nOpcao)

	if nOpcao == 1

		oPanelVenda:Show()
		oPanelCred:Hide()
		oPanelPrecos:Hide()
		oPanelConfig:Hide()

	elseif nOpcao == 2

		oPanelVenda:Hide()
		oPanelCred:Show()
		oPanelPrecos:Hide()
		oPanelConfig:Hide()

	elseif nOpcao == 3

		oPanelVenda:Hide()
		oPanelCred:Hide()
		oPanelPrecos:Show()
		oPanelConfig:Hide()

	elseif nOpcao == 4

		oPanelVenda:Hide()
		oPanelCred:Hide()
		oPanelPrecos:Hide()
		oPanelConfig:Show()

	else
		Alert("Layout Inválido")
	endif

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UHistVend ºAutor³ Wellington Gonçalves º Data ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o painel do histórico de vendas		      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel de dados							  º±±
±±		     ³ 2 - Tipo de visão: 1=Sintetico;2=Analitico				  º±±
±±		     ³ 3 - Opcao de visualizacao								  º±±
±±		     ³ 4 - Array com o status dos menus							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UHistVend(cTipo,oPanelDados,aDados,cPerspectiva,cCliente,cLoja)

	Local oFntGroup 	:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local nPanelHeight	:= oPanelDados:nClientHeight / 2
	Local nPanelWidth	:= oPanelDados:nClientWidth / 2
	Local nColorPanel 	:= 13553358
	Local oPanel
	Local oPanel1
	Local oScroll1
	Local oGroupCheques

// crio o panel do botao
	@ 000, 000 MSPANEL oPanel PROMPT "" SIZE nPanelWidth, nPanelHeight OF oPanelDados

// crio o objeto do tipo SCROLL
	oScroll1 := TScrollArea():New(oPanel,000,000,nPanelHeight,nPanelWidth,.T.,.T.,.T.)

// habilito a função de deslizar do SCROLL
	oScroll1:lTracking := .T.

// se o tipo for sintético
	if cTipo == "1"

		// crio o panel dos dados
		@ 000, 000 MSPANEL oPanel1 PROMPT "" SIZE nPanelWidth , iif(nPanelHeight > 395 , nPanelHeight , 395) OF oScroll1 LOWERED

		oScroll1:SetFrame( oPanel1 )

		VendaSintetico(oPanel1,aDados,cPerspectiva,cCliente,cLoja)

	else

		// crio o panel dos dados
		@ 000, 000 MSPANEL oPanel1 PROMPT "" SIZE nPanelWidth , iif(nPanelHeight > 395 , nPanelHeight , 395) OF oScroll1 LOWERED

		oScroll1:SetFrame( oPanel1 )

		VendaAnalitico(oPanel1,aDados,cPerspectiva,cCliente,cLoja)

	endif

Return(oPanel)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UHistCred ºAutor³ Wellington Gonçalves º Data ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o painel do histórico de crédito	      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel de dados							  º±±
±±		     ³ 2 - Tipo de visão: 1=Sintetico;2=Analitico				  º±±
±±		     ³ 3 - Opcao de visualizacao								  º±±
±±		     ³ 4 - Array com o status dos menus							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UHistCred(cTipo,oPanelDados,aHistCredito)

	Local oFonteSay		:= TFont():New("Verdana",,018,,.F.,,,,,.F.,.F.)
	Local oFntGroup 	:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local nPanelHeight	:= oPanelDados:nClientHeight / 2
	Local nPanelWidth	:= oPanelDados:nClientWidth / 2

	Local aRisco		:= {}
	Local cRisco 		:= ""
	Local cBloqGeral	:= ""
	Local cBloqTitRec	:= ""
	Local cBloqChq		:= ""
	Local cBloqSaque	:= ""

	Local oScroll1
	Local oPanel
	Local oPanel1
	Local oGroupCheques
	Local nColuna 		:= 5
	Local nLinha		:= 0
	Local nTamGet		:= 86
	Local nColorSim		:= 255
	Local nColorNao		:= 3707958

	if Empty(aHistCredito)
		aRisco := {"","",""}
	else
		aRisco := aHistCredito[5]
	endif

// crio o panel geral
	@ 000, 000 MSPANEL oPanel PROMPT "" SIZE nPanelWidth, nPanelHeight OF oPanelDados

// crio panel dos riscos
	@ nPanelHeight -  40, 000 MSPANEL oPanel2 PROMPT "" SIZE nPanelWidth, nPanelHeight OF oPanel

// crio o objeto do tipo SCROLL
	oScroll1 := TScrollArea():New(oPanel,000,000,nPanelHeight - 40,nPanelWidth,.T.,.T.,.T.)

// habilito a função de deslizar do SCROLL
	oScroll1:lTracking := .T.

// se o tipo for sintético
	if cTipo == "1"

		// crio o panel dos dados
		@ 000, 000 MSPANEL oPanel1 PROMPT "" SIZE nPanelWidth , nPanelHeight - 40 OF oScroll1 LOWERED

		oScroll1:SetFrame( oPanel1 )

		CredSintetico(oPanel1,aHistCredito)

	else

		// crio o panel dos dados
		@ 000, 000 MSPANEL oPanel1 PROMPT "" SIZE nPanelWidth , iif ( (nPanelHeight - 40) > 350.5 , nPanelHeight - 40 , 350.5) OF oScroll1 LOWERED

		oScroll1:SetFrame( oPanel1 )

		CredAnalitico(oPanel1,aHistCredito)

	endif

//////////////////////////// PAINÉIS DE BLOQUEIO //////////////////////////////

	cRisco 		:= aRisco[3]
	cBloqGeral	:= aRisco[1]
	cBloqSaque	:= aRisco[2]

	@ 005 , nColuna + 35 SAY oSay1 PROMPT "Risco" SIZE nTamGet, 015 OF oPanel2 FONT oFonteSay PIXEL
	@ 015 , nColuna MSPANEL oPanelRisco PROMPT cRisco SIZE nTamGet, 020 OF oPanel2 COLORS 0,255 CENTERED LOWERED
	oPanelRisco:oFont := oFonteSay

	nColuna += nTamGet + 10

	@ 005 , nColuna + 18 SAY oSay2 PROMPT "Bloqueio Geral" SIZE nTamGet, 015 OF oPanel2 FONT oFonteSay PIXEL
	@ 015 , nColuna MSPANEL oPanelBlqGeral PROMPT cBloqGeral SIZE nTamGet, 020 OF oPanel2 COLORS 0 , iif(cBloqGeral == "SIM",nColorSim,nColorNao) CENTERED LOWERED
	oPanelBlqGeral:oFont := oFonteSay

	nColuna += nTamGet + 10

	@ 005 , nColuna + 10 SAY oSay5 PROMPT "Bloqueio de Saque" SIZE nTamGet, 015 OF oPanel2 FONT oFonteSay PIXEL
	@ 015 , nColuna MSPANEL oPanelBlqSaque PROMPT cBloqSaque SIZE nTamGet - 2, 020 OF oPanel2 COLORS 0 , iif(cBloqSaque == "SIM",nColorSim,nColorNao) CENTERED LOWERED
	oPanelBlqSaque:oFont := oFonteSay

Return(oPanel)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UPrecos º Autor ³ Wellington Gonçalves º Data ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o painel do preço					      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel de dados							  º±±
±±		     ³ 2 - Tipo de visão: 1=Sintetico;2=Analitico				  º±±
±±		     ³ 3 - Opcao de visualizacao								  º±±
±±		     ³ 4 - Array com o status dos menus							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UPrecos(oPanelDados,aPrecos)

	Local oFntGroup 	:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local oFonteSay		:= TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
	Local nPanelHeight	:= oPanelDados:nClientHeight / 2
	Local nPanelWidth	:= oPanelDados:nClientWidth / 2


	Local nLinha		:= 5
	Local nRadio	 	:= 2 //Vigente
	Local cCSSRadio		:= ""
	Local cCSSGroup		:= ""
	Local aItensRadio	:= {"Todos","Vigente","Encerrado"}
	Local oScroll1
	Local oGroup
	Local oPanel
	Local oPanel1
	Local oRadio
	Local oGridPrecos

// CSS do objeto group para colorir a borda
	cCSSGroup := " QGroupBox { "
	cCSSGroup += " border: 1px solid #000000; "
	cCSSGroup += " padding-top: 0px; "
	cCSSGroup += " } "

// crio o css para aplicar no radiobutton
	cCSSRadio := " QRadioButton { "
	cCSSRadio += " font-size: 16px; "
	cCSSRadio += " } "
	cCSSRadio += " QRadioButton::indicator { "
	cCSSRadio += "	width: 20px; "
	cCSSRadio += "	height: 20px; "
	cCSSRadio += " } "

// crio o panel
	@ 000, 000 MSPANEL oPanel PROMPT "" SIZE nPanelWidth, nPanelHeight OF oPanelDados

// crio o objeto do tipo SCROLL
	oScroll1 := TScrollArea():New(oPanel,000,000,nPanelHeight,nPanelWidth,.T.,.T.,.T.)

// habilito a função de deslizar do SCROLL
	oScroll1:lTracking := .T.

// crio o panel dos dados
	@ 000, 000 MSPANEL oPanel1 PROMPT "" SIZE nPanelWidth, nPanelHeight OF oScroll1 LOWERED

// aponto o panel filho do scroll
	oScroll1:SetFrame( oPanel1 )

// chamo grid para visualização das filiais
	oGridPrecos := GridPrecos(oPanel1,nLinha + 60,aPrecos)

// retiro a barra de rolagem vertical
	oGridPrecos:oBrowse:LHSCROLL := .F.

	@ nLinha, 005 GROUP oGroup TO 040 , 240 PROMPT "Informe o tipo de visualização: " OF oPanel1 PIXEL
	oGroup:oFont := oFntGroup
	oGroup:SetCss(cCSSGroup)

	nLinha += 15

// crio o radio com as opções de visualização
	oRadio := TRadMenu():Create(oPanel1,{|u| iif( PCount() == 0,nRadio,nRadio := u) },nLinha,030,aItensRadio,, {|| AtuPrecos(nRadio,oGridPrecos,aPrecos) } ,,,,,,200,50,,,,.T.,.T.)
// atulizo o grid de acordo com opção padrão (vigente)
	AtuPrecos(nRadio,oGridPrecos,aPrecos)

// aplico o CSS no radio
	oRadio:SetCss(cCSSRadio)

	nLinha += 30

	@ nLinha , 005 SAY oSay1 PROMPT "Preços negociados:" SIZE 150, 015 OF oPanel1 FONT oFonteSay PIXEL

Return(oPanel)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ AtuPrecos º Autor ³ Wellington Gonçalves º Data³25/11/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função chamada na seleção do tipo de preço do objeto radio º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function AtuPrecos(nRadio,oGridPrecos,aPrecos)

	Local oOK 		:= LoadBitmap(GetResources(),"OK")
	Local oNO 		:= LoadBitmap(GetResources(),"CANCEL")
	Local aItens	:= {}
	Local nX := 0
	Local oStatus

	oGridPrecos:aCols := {}

// aPrecos - [01]-FILIAL,[02]-FORMA,[03]-CONDICAO,[04]-PRODUTO,[05]-DESCRICAO,[06]-PRC BASE,[07]-PRC VENDA,[08]-DESC/ACRES,[09]-DT VIGENCIA,[10]-HR VIGENCIA
// aPrecos - [01]-FILIAL,[02]-FORMA,[03]-CONDICAO,[04]-PRODUTO,[05]-DESCRICAO,[06]-PRC VENDA,[07]-DT VIGENCIA,[08]-HR VIGENCIA
	For nX := 1 To Len(aPrecos)

		If U25->(FieldPos("U25_DESPBA"))>0
			If Empty(aPrecos[nX,09]) .OR. aPrecos[nX,09] > dDataBase .OR. ( aPrecos[nX,09] == dDataBase .AND. aPrecos[nX,10] > SubStr(Time(),1,5))
				oStatus := oOK
			Else
				oStatus := oNO
			EndIf

			//{"VIGENCIA","U25_FILIAL","U25_DESFPG","U25_DESCPG","U25_PRODUT","U25_DESPRO","U25_PRCBAS","U25_PRCVEN","U25_DESPBA"}
			If nRadio == 1 // todos os preços
				aadd(aItens,{oStatus,aPrecos[nX,01],aPrecos[nX,02],aPrecos[nX,03],aPrecos[nX,04],aPrecos[nX,05],aPrecos[nX,06],aPrecos[nX,07],aPrecos[nX,08],.F.})
			ElseIf nRadio == 2 .AND. oStatus:cName == "OK"   // preços vigentes
				aadd(aItens,{oStatus,aPrecos[nX,01],aPrecos[nX,02],aPrecos[nX,03],aPrecos[nX,04],aPrecos[nX,05],aPrecos[nX,06],aPrecos[nX,07],aPrecos[nX,08],.F.})
			ElseIf nRadio == 3 .AND. oStatus:cName == "CANCEL"  // preços encerrados
				aadd(aItens,{oStatus,aPrecos[nX,01],aPrecos[nX,02],aPrecos[nX,03],aPrecos[nX,04],aPrecos[nX,05],aPrecos[nX,06],aPrecos[nX,07],aPrecos[nX,08],.F.})
			EndIf
		Else
			If Empty(aPrecos[nX,07]) .OR. aPrecos[nX,07] > dDataBase .OR. ( aPrecos[nX,07] == dDataBase .AND. aPrecos[nX,08] > SubStr(Time(),1,5))
				oStatus := oOK
			Else
				oStatus := oNO
			EndIf

			//{"VIGENCIA","U25_FILIAL","U25_DESFPG","U25_DESCPG","U25_PRODUT","U25_DESPRO","U25_PRCVEN"}
			If nRadio == 1 // todos os preços
				aadd(aItens,{oStatus,aPrecos[nX,01],aPrecos[nX,02],aPrecos[nX,03],aPrecos[nX,04],aPrecos[nX,05],aPrecos[nX,06],.F.})
			ElseIf nRadio == 2 .AND. oStatus:cName == "OK"   // preços vigentes
				aadd(aItens,{oStatus,aPrecos[nX,01],aPrecos[nX,02],aPrecos[nX,03],aPrecos[nX,04],aPrecos[nX,05],aPrecos[nX,06],.F.})
			ElseIf nRadio == 3 .AND. oStatus:cName == "CANCEL"  // preços encerrados
				aadd(aItens,{oStatus,aPrecos[nX,01],aPrecos[nX,02],aPrecos[nX,03],aPrecos[nX,04],aPrecos[nX,05],aPrecos[nX,06],.F.})
			EndIf
		EndIf
	Next nX

// ordeno o array pela vigencia + filial + descrição da forma de pagamento + produto
	If Len(aItens) > 0
		aItens := ASort(aClone(aItens),,,{|x,y| x[1]:cName + x[2] + x[3] + x[5] > y[1]:cName + y[2] + y[3] + y[5] })
	EndIf

	oGridPrecos:aCols := aClone(aItens)
	oGridPrecos:Refresh()

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ UConfig º Autor ³ Wellington Gonçalves º Data ³ 05/08/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o painel de configurações			      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel de dados							  º±±
±±		     ³ 2 - Tipo de visão: 1=Sintetico;2=Analitico				  º±±
±±		     ³ 3 - Opcao de visualizacao								  º±±
±±		     ³ 4 - Array com o status dos menus							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function UConfig(oPanelDados,cTipo,aFiliais,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,lPergunta)

	Local oFntGroup 	:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local oFonteSay		:= TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
	Local nPanelHeight	:= oPanelDados:nClientHeight / 2
	Local nPanelWidth	:= oPanelDados:nClientWidth / 2

	Local oPanel1
	Local nLinha		:= 5
	Local nRadio	 	:= iif(cTipo == "1" , 1 , 2)
	Local aItensRadio	:= {"Sintético","Analítico"}
	Local cCSSGroup		:= ""
	Local cCSSRadio		:= ""
	Local lMarkTudo		:= .T.
	Local oRadio
	Local oGroup
	Local oPanel
	Local oBtnRefresh
	Local oGridFiliais

// CSS do objeto group para colorir a borda
	cCSSGroup := " QGroupBox { "
	cCSSGroup += " border: 1px solid #000000; "
	cCSSGroup += " padding-top: 0px; "
	cCSSGroup += " } "

// crio o css para aplicar no radiobutton
	cCSSRadio := " QRadioButton { "
	cCSSRadio += " font-size: 16px; "
	cCSSRadio += " } "
	cCSSRadio += " QRadioButton::indicator { "
	cCSSRadio += "	width: 20px; "
	cCSSRadio += "	height: 20px; "
	cCSSRadio += " } "

// crio o panel
	@ 000, 000 MSPANEL oPanel PROMPT "" SIZE nPanelWidth, nPanelHeight OF oPanelDados

// crio o objeto do tipo SCROLL
	oScroll1 := TScrollArea():New(oPanel,000,000,nPanelHeight,nPanelWidth,.T.,.T.,.T.)

// habilito a função de deslizar do SCROLL
	oScroll1:lTracking := .T.

// crio o panel dos dados
	@ 000, 000 MSPANEL oPanel1 PROMPT "" SIZE nPanelWidth, nPanelHeight OF oScroll1 LOWERED

// aponto o panel filho do scroll
	oScroll1:SetFrame( oPanel1 )

	@ nLinha, 005 GROUP oGroup TO 040 , 200 PROMPT "Informe o tipo de visualização: " OF oPanel1 PIXEL
	oGroup:oFont := oFntGroup
	oGroup:SetCss(cCSSGroup)

	nLinha += 15

// crio o radio com as opções de visualização
	oRadio := TRadMenu():Create(oPanel1,{|u| iif( PCount() == 0,nRadio,nRadio := u) },nLinha,030,aItensRadio,, {|| iif(nRadio == 1 , cTipo := "1" , cTipo := "2") } ,,,,,,200,50,,,,.T.,.T.)

// aplico o CSS no rádio
	oRadio:SetCss(cCSSRadio)

	nLinha += 30

	@ nLinha , 005 SAY oSay1 PROMPT "Seleção de Empresas consideradas na análise:" SIZE 250, 015 OF oPanel1 FONT oFonteSay PIXEL

	nLinha += 15

// chamo grid para visualização das filiais
	oGridFiliais := GridFiliais(oPanel1,nLinha,aFiliais)

// retiro a barra de rolagem vertical
	oGridFiliais:oBrowse:LHSCROLL := .F.

// duplo clique no grid
	oGridFiliais:oBrowse:bLDblClick := {|| CliqueFiliais(oGridFiliais,@aFiliais) }

// clique marca todos no header
	oGridFiliais:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol == 1,(HdCliqFiliais(oGridFiliais,@aFiliais,@lMarkTudo),oBrw:SetFocus()),)}

// botão de atualizar
//oBtnRefresh:= TBTNPDV():New(nPanelHeight - 22,416,110/2,35/2,oPanel1,"PCLBTNATU.png", {|| iif(aScan(aFiliais,{|x| x[1] == "OK" }) == 0,Alert("Selecione uma filial!"),(lPergunta := .F., oDlgHistorico:End()) )}, "Atualizar")
	oBtnRefresh := TButton():New( nPanelHeight - 22,;
		416,;
		"Atualizar",;
		oPanel1,;
		{|| iif(aScan(aFiliais,{|x| x[1] == "OK" }) == 0,Alert("Selecione uma filial!"),(lPergunta := .F., oDlgHistorico:End()) )},;
		110/2,;
		36/2,;
		,,,.T.,;
		,,,{|| .T.})
	oBtnRefresh:SetCSS( POSCSS (GetClassName(oBtnRefresh), CSS_BTN_FOCAL ))

// botão de consulta de entidades
//oBtnRefresh:= TBTNPDV():New(nPanelHeight - 22,351,110/2,35/2,oPanel1,"PCLBTNCONSG.png", {|| iif(aScan(aFiliais,{|x| x[1] == "OK" }) == 0,Alert("Selecione uma filial!"),iif( U_TRETA41C(@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca) , (cPerspectiva := "" , oDlgHistorico:End() ) , ))}, "Atualizar")
	oBtnRefresh := TButton():New( nPanelHeight - 22,;
		351,;
		"Consultar",;
		oPanel1,;
		{|| iif(aScan(aFiliais,{|x| x[1] == "OK" }) == 0,Alert("Selecione uma filial!"),iif( U_TRETA41C(@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca) , (cPerspectiva := "" , oDlgHistorico:End() ) , ))},;
		110/2,;
		36/2,;
		,,,.T.,;
		,,,{|| .T.})
	oBtnRefresh:SetCSS( POSCSS (GetClassName(oBtnRefresh), CSS_BTN_FOCAL ))

Return(oPanel)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ CliqueFiliais ºAutor³Wellington Gonçalvesº Data³25/10/2015 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função chamada no duplo clique no grid de filiais		  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CliqueFiliais(oGrid,aFiliais)

	Local oOK 			:= LoadBitmap(GetResources(),"CHECKED")
	Local oNO 			:= LoadBitmap(GetResources(),"UNCHECKED")
	Local nX			:= 0
	Local nPosFil		:= 0
	Local oNewStatus

	if oGrid:aCols[oGrid:oBrowse:nRowPos,1]:cName == "CHECKED"
		oNewStatus := oNO
	else
		oNewStatus := oOK
	endif

	oGrid:aCols[oGrid:oBrowse:nRowPos,1] := oNewStatus

	oGrid:Refresh()

	For nX := 1 To Len(oGrid:aCols)

		nPosFil := aScan(aFiliais,{|x| AllTrim(x[2]) == oGrid:aCols[nX,2] })

		if oGrid:aCols[nX,1]:cName == "CHECKED" // se o objeto for checked, marca a filial no array de filiais
			aFiliais[nPosFil,1] := "OK"
		else
			aFiliais[nPosFil,1] := "NO"
		endif

	Next nX

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ HdCliqFiliais ºAutor³Wellington Gonçalvesº Data³17/05/2016 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função chamada no clique do cabeçalho do grid			  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function HdCliqFiliais(oGrid,aFiliais,lMarkTudo)

	Local oOK 			:= LoadBitmap(GetResources(),"CHECKED")
	Local oNO 			:= LoadBitmap(GetResources(),"UNCHECKED")
	Local nX			:= 0
	Local nPosFil		:= 0
	Local oNewStatus

	if lMarkTudo
		oNewStatus 	:= oNO
		lMarkTudo 	:= .F.
	else
		oNewStatus 	:= oOK
		lMarkTudo 	:= .T.
	endif

	For nX := 1 To Len(oGrid:aCols)

		// atualizo o status do objeto
		oGrid:aCols[nX,1] := oNewStatus

		// verifico em qual posição esta filial se encontra no array de filiais
		nPosFil := aScan(aFiliais,{|x| AllTrim(x[2]) == oGrid:aCols[nX,2] })

		// se o objeto for checked, marca a filial no array de filiais
		if oGrid:aCols[nX,1]:cName == "CHECKED"
			aFiliais[nPosFil,1] := "OK"
		else
			aFiliais[nPosFil,1] := "NO"
		endif

	Next nX

	oGrid:Refresh()

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ CredSintetico ºAutor³ Wellington Gonçalves ºData³26/08/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Histórico de crédito sintético						      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel										  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CredSintetico(oPanel,aHistCredito)

	Local oFntGroup 	:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local oFonteSay		:= TFont():New("Verdana",,018,,.F.,,,,,.F.,.F.)
	Local nPanelHeight	:= oPanel:nClientHeight / 2
	Local nPanelWidth	:= oPanel:nClientWidth / 2
	Local nLinha		:= 0
	Local nColorSay		:= 0
	Local cQtdChqDisp	:= "0"
	Local cValChqDisp 	:= "0"
	Local cQtdChqComp	:= "0"
	Local cValChqComp 	:= "0"
	Local cQtdChqPend	:= "0"
	Local cValChqPend 	:= "0"
	Local cPerChqPend	:= "0"
	Local cQtdChqDPg	:= "0"
	Local cValChqDPg	:= "0"
	Local cQtdChqDAb	:= "0"
	Local cValChqDAb	:= "0"
	Local cValSldLim 	:= "0"
	Local cQtdTitAb 	:= "0"
	Local cValTitAb 	:= "0"
	Local cQtdTitLiq 	:= "0"
	Local cValTitLiq 	:= "0"
	Local cQtdTitVen 	:= "0"
	Local cValTitVen 	:= "0"
	Local cQtdMedia 	:= "0"
	Local cValMedia 	:= "0"
	Local cPerChqDisp	:= "0"
	Local cPerChqComp	:= "0"
	Local cPerChqDPg	:= "0"
	Local cPerChqDAb	:= "0"
	Local cCSSGroup		:= ""

	Local aCheques		:= {}
	Local aTitulos		:= {}
	Local aCredito		:= {}

// CSS do objeto group para colorir a borda
	cCSSGroup := " QGroupBox { "
	cCSSGroup += " border: 1px solid #000000; "
	cCSSGroup += " padding-top: 0px; "
	cCSSGroup += " } "

	if Empty(aHistCredito)

		aCheques := {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		aTitulos := {0,0,0,0,0,0,0,0,0}
		aCredito := {0,0,0,0}

	else

		aCheques := aHistCredito[1] // dados de cheques
		aTitulos := aHistCredito[2] // dados de títulos
		aCredito := aHistCredito[3] // dados de limites de crédito

	endif

//////////////////////////// ANÁLISE DE CHEQUES ///////////////////////////////
	@ 005, 005 GROUP oGroupCheques TO 080 , 473 PROMPT " Análise de Cheques Emitidos " OF oPanel PIXEL
	oGroupCheques:oFont := oFntGroup
	oGroupCheques:SetCss(cCSSGroup)

	nLinha := 18

	cQtdChqDisp	:= AllTrim(Transform(aCheques[01], "@E 999,999,999.99"))
	cValChqDisp := AllTrim(Transform(aCheques[02], "@E 999,999,999.99"))
	cQtdChqComp	:= AllTrim(Transform(aCheques[03], "@E 999,999,999.99"))
	cValChqComp := AllTrim(Transform(aCheques[04], "@E 999,999,999.99"))
	cQtdChqPend	:= AllTrim(Transform(aCheques[05], "@E 999,999,999.99"))
	cValChqPend := AllTrim(Transform(aCheques[06], "@E 999,999,999.99"))
	cQtdChqDPg	:= AllTrim(Transform(aCheques[07], "@E 999,999,999.99"))
	cValChqDPg	:= AllTrim(Transform(aCheques[08], "@E 999,999,999.99"))
	cQtdChqDAb	:= AllTrim(Transform(aCheques[09], "@E 999,999,999.99"))
	cValChqDAb	:= AllTrim(Transform(aCheques[10], "@E 999,999,999.99"))

	cPerChqDisp	:= AllTrim(Transform(aCheques[11], "@E 999,999,999.99")) + " %" // percentual do valor de limite de cheque disponível
	cPerChqComp	:= AllTrim(Transform(aCheques[12], "@E 999,999,999.99")) + " %" // percentual de cheques compensados
	cPerChqPend	:= AllTrim(Transform(aCheques[13], "@E 999,999,999.99")) + " %" // percentual de cheques pendentes
	cPerChqDPg	:= AllTrim(Transform(aCheques[14], "@E 999,999,999.99")) + " %" // percentual de cheques devolvidos pagos
	cPerChqDAb	:= AllTrim(Transform(aCheques[15], "@E 999,999,999.99")) + " %" // percentual de cheques devolvidos pendentes

	@ nLinha , 005 SAY oSay1 PROMPT "Limite Disponível de Cheques" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay2 PROMPT cQtdChqDisp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay3 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay4 PROMPT cValChqDisp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL  CENTER
	@ nLinha , 340 SAY oSay5 PROMPT cPerChqDisp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay6 PROMPT "Cheques Compensados" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay7 PROMPT cQtdChqComp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay8 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay9 PROMPT cValChqComp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay10 PROMPT cPerChqComp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay11 PROMPT "Cheques Pendentes" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay12 PROMPT cQtdChqPend SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay13 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay14 PROMPT cValChqPend SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay15 PROMPT cPerChqPend SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay16 PROMPT "Total de Cheques Devolvidos" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay17 PROMPT cQtdChqDPg SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay18 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay19 PROMPT cValChqDPg SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay20 PROMPT cPerChqDPg SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay21 PROMPT "Cheques Devolvidos Pendentes" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay22 PROMPT cQtdChqDAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay23 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay24 PROMPT cValChqDAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay25 PROMPT cPerChqDAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER


//////////////////////////// ANÁLISE DE TÍTULOS ///////////////////////////////

	cValSldLim 	:= AllTrim(Transform(aTitulos[01], "@E 999,999,999.99"))
	cQtdTitAb 	:= AllTrim(Transform(aTitulos[02], "@E 999,999,999.99"))
	cValTitAb 	:= AllTrim(Transform(aTitulos[03], "@E 999,999,999.99"))
	cQtdTitLiq 	:= AllTrim(Transform(aTitulos[04], "@E 999,999,999.99"))
	cValTitLiq 	:= AllTrim(Transform(aTitulos[05], "@E 999,999,999.99"))
	cQtdTitVen 	:= AllTrim(Transform(aTitulos[06], "@E 999,999,999.99"))
	cValTitVen 	:= AllTrim(Transform(aTitulos[07], "@E 999,999,999.99"))
	cQtdMedia 	:= AllTrim(Transform(aTitulos[08], "@E 999,999,999.99"))
	cValMedia 	:= AllTrim(Transform(aTitulos[09], "@E 999,999,999.99"))

	@ 090, 005 GROUP oGroupCheques TO 165 , 473 PROMPT " Análise de Títulos " OF oPanel PIXEL
	oGroupCheques:oFont := oFntGroup
	oGroupCheques:SetCss(cCSSGroup)

	nLinha := 103

	@ nLinha , 005 SAY oSay26 PROMPT "Limite de Crédito Disponível" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay27 PROMPT " - " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay28 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay29 PROMPT cValSldLim SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay30 PROMPT "Títulos em Aberto" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay31 PROMPT cQtdTitAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay32 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay33 PROMPT cValTitAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay34 PROMPT "Títulos Liquidados" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay35 PROMPT cQtdTitLiq SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay36 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay37 PROMPT cValTitLiq SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay38 PROMPT "Títulos Vencidos" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay39 PROMPT cQtdTitVen SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay40 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay41 PROMPT cValTitVen SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay42 PROMPT "Média de Atraso de Títulos" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay43 PROMPT cQtdMedia SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay44 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay45 PROMPT cValMedia SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ CredAnalitico ºAutor³ Wellington Gonçalves ºData³26/08/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Histórico de crédito analítico						      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel										  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CredAnalitico(oPanel,aHistCredito)

	Local oFntGroup 	:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local oFonteSay		:= TFont():New("Verdana",,018,,.F.,,,,,.F.,.F.)
	Local oFonteSay2	:= TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
	Local oFontGrid		:= TFont():New("Arial",,016,,.F.,,,,,.F.,.F.)
	Local nPanelHeight	:= oPanel:nClientHeight / 2
	Local nPanelWidth	:= oPanel:nClientWidth / 2
	Local nColorSay		:= 0
	Local nLinha		:= 0
	Local cQtdChqDisp	:= "0"
	Local cValChqDisp 	:= "0"
	Local cQtdChqComp	:= "0"
	Local cValChqComp 	:= "0"
	Local cQtdChqPend	:= "0"
	Local cValChqPend 	:= "0"
	Local cQtdChqDPg	:= "0"
	Local cValChqDPg	:= "0"
	Local cQtdChqDAb	:= "0"
	Local cValChqDAb	:= "0"
	Local cValSldLim 	:= "0"
	Local cQtdTitAb 	:= "0"
	Local cValTitAb 	:= "0"
	Local cQtdTitLiq 	:= "0"
	Local cValTitLiq 	:= "0"
	Local cQtdTitVen 	:= "0"
	Local cValTitVen 	:= "0"
	Local cQtdMedia 	:= "0"
	Local cValMedia 	:= "0"
	Local cQtdSaqAnt	:= "0"
	Local cValSaqAnt	:= "0"
	Local cPerChqComp	:= "0"
	Local cPerChqPend	:= "0"
	Local cPerChqDPg	:= "0"
	Local cPerChqDAb	:= "0"
	Local aCheques		:= {}
	Local aTitulos		:= {}
	Local aCredito		:= {}
	Local cCSSGroup 	:= ""
	Local oGridLimCredito
	Local oGroupTitulos
	Local oGroupCheques

// CSS do objeto group para colorir a borda
	cCSSGroup := " QGroupBox { "
	cCSSGroup += " border: 1px solid #000000; "
	cCSSGroup += " padding-top: 0px; "
	cCSSGroup += " } "

	if Empty(aHistCredito)

		aCheques 	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		aTitulos	:= {0,0,0,0,0,0,0,0,0}
		aCredito	:= {0,0,0,0}

	else

		aCheques 	:= aHistCredito[1] // dados de cheques
		aTitulos 	:= aHistCredito[2] // dados de títulos
		aCredito 	:= aHistCredito[3] // dados de limites de crédito

	endif

//////////////////////////// ANÁLISE DE CHEQUES ///////////////////////////////
	@ 005, 005 GROUP oGroupCheques TO 070 , 473 PROMPT " Análise de Cheques Emitidos " OF oPanel PIXEL
	oGroupCheques:oFont := oFntGroup
	oGroupCheques:SetCss(cCSSGroup)

	cQtdChqComp	:= AllTrim(Transform(aCheques[03], "@E 999,999,999.99"))
	cValChqComp := AllTrim(Transform(aCheques[04], "@E 999,999,999.99"))
	cQtdChqPend	:= AllTrim(Transform(aCheques[05], "@E 999,999,999.99"))
	cValChqPend := AllTrim(Transform(aCheques[06], "@E 999,999,999.99"))
	cQtdChqDPg	:= AllTrim(Transform(aCheques[07], "@E 999,999,999.99"))
	cValChqDPg	:= AllTrim(Transform(aCheques[08], "@E 999,999,999.99"))
	cQtdChqDAb	:= AllTrim(Transform(aCheques[09], "@E 999,999,999.99"))
	cValChqDAb	:= AllTrim(Transform(aCheques[10], "@E 999,999,999.99"))

	cPerChqComp	:= AllTrim(Transform(aCheques[12], "@E 999,999,999.99")) + " %" // percentual de cheques compensados
	cPerChqPend	:= AllTrim(Transform(aCheques[13], "@E 999,999,999.99")) + " %" // percentual de cheques pendentes
	cPerChqDPg	:= AllTrim(Transform(aCheques[14], "@E 999,999,999.99")) + " %" // percentual de cheques devolvidos pagos
	cPerChqDAb	:= AllTrim(Transform(aCheques[15], "@E 999,999,999.99")) + " %" // percentual de cheques devolvidos pendentes

	nLinha := 18

	@ nLinha , 005 SAY oSay1 PROMPT "Cheques Compensados" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay2 PROMPT cQtdChqComp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay3 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay4 PROMPT cValChqComp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay5 PROMPT cPerChqComp SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay36 PROMPT "Cheques Pendentes" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay37 PROMPT cQtdChqPend SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay38 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay39 PROMPT cValChqPend SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay40 PROMPT cPerChqPend SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay6 PROMPT "Total de Cheques Devolvidos" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay7 PROMPT cQtdChqDPg SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay8 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay9 PROMPT cValChqDPg SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay10 PROMPT cPerChqDPg SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay11 PROMPT "Cheques Devolvidos Pendentes" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay12 PROMPT cQtdChqDAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay13 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay14 PROMPT cValChqDAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 340 SAY oSay15 PROMPT cPerChqDAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER


//////////////////////////// ANÁLISE DE TÍTULOS ///////////////////////////////
	@ 080, 005 GROUP oGroupTitulos TO 155 , 473 PROMPT " Análise de Títulos " OF oPanel PIXEL
	oGroupTitulos:oFont := oFntGroup
	oGroupTitulos:SetCss(cCSSGroup)

	cQtdTitAb 	:= AllTrim(Transform(aTitulos[02], "@E 999,999,999.99"))
	cValTitAb 	:= AllTrim(Transform(aTitulos[03], "@E 999,999,999.99"))
	cQtdTitLiq 	:= AllTrim(Transform(aTitulos[04], "@E 999,999,999.99"))
	cValTitLiq 	:= AllTrim(Transform(aTitulos[05], "@E 999,999,999.99"))
	cQtdTitVen 	:= AllTrim(Transform(aTitulos[06], "@E 999,999,999.99"))
	cValTitVen 	:= AllTrim(Transform(aTitulos[07], "@E 999,999,999.99"))
	cQtdMedia 	:= AllTrim(Transform(aTitulos[08], "@E 999,999,999.99"))
	cValMedia 	:= AllTrim(Transform(aTitulos[09], "@E 999,999,999.99"))
	cQtdSaqAnt	:= AllTrim(Transform(0, "@E 999,999,999.99"))
	cValSaqAnt	:= AllTrim(Transform(0, "@E 999,999,999.99"))

	nLinha := 93

	@ nLinha , 005 SAY oSay16 PROMPT "Títulos em Aberto" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay17 PROMPT cQtdTitAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay18 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay19 PROMPT cValTitAb SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay20 PROMPT "Títulos Liquidados" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay21 PROMPT cQtdTitLiq SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay22 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay23 PROMPT cValTitLiq SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay24 PROMPT "Títulos Vencidos" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay25 PROMPT cQtdTitVen SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay26 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay27 PROMPT cValTitVen SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay28 PROMPT "Média de Atraso de Títulos" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay29 PROMPT cQtdMedia SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay30 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay31 PROMPT cValMedia SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 12

	@ nLinha , 005 SAY oSay32 PROMPT "Saques Realizados no Mês Anterior" SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 110 SAY oSay33 PROMPT cQtdSaqAnt SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 170 SAY oSay34 PROMPT " R$ " SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 245 SAY oSay35 PROMPT cValSaqAnt SIZE 200, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 25

	@ nLinha , 005 SAY oSay1 PROMPT "Limite de Crédito:" SIZE 200, 015 OF oPanel FONT oFonteSay2 PIXEL

	nLinha += 15

// chamo grid para visualização dos limites de crédito
	oGridLimCredito := GridLimCredito(oPanel,nLinha,aCredito)

// retiro a barra de rolagem vertical
	oGridLimCredito:oBrowse:LHSCROLL := .F.

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ GridLimCredito ºAutor³Wellington Gonçalves ºData³26/08/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o grid de limite de crédito		          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function GridLimCredito(oPanel,nLinha,aDados)

	Local oGrid
	Local aFields 	:= {"","A1_XLC","A1_XLIMSQ"}
	Local aHeader	:= {}
	Local aItens	:= {}
	Local aAlterFields 	:= {}
	Local nX := 0

	For nX := 1 to Len(aFields)

		if Empty(aFields[nX])
			Aadd(aHeader, {Space(10),'TIPO','@!',30,0,'','€€€€€€€€€€€€€€','C','','','',''})
		else

			If aFields[nX] == "A1_XLC"
				Aadd(aHeader, U_UAHEADER(aFields[nX]))
				aHeader[Len(aHeader)][01] := "Geral"
			ElseIf aFields[nX] == "A1_XLIMSQ"
				Aadd(aHeader, U_UAHEADER(aFields[nX]))
				aHeader[Len(aHeader)][01] := "Saque"
			Else
				Aadd(aHeader, U_UAHEADER(aFields[nX]))
			EndIf

		endif

	Next nX

	aadd(aItens,{"Valor",aDados[1],aDados[3],.F.})
	aadd(aItens,{"Saldo",aDados[2],aDados[4],.F.})

//oGrid := GRIDPOSTO():New(nLinha,005,467,050,oPanel,aHeader,aItens,2)
	oGrid := MsNewGetDados():New( nLinha, 005, nLinha+050, 300,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 9999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aHeader, aItens)

Return(oGrid)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ VendaSinteticoºAutor³ Wellington Gonçalves ºData³09/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Histórico vendas sintético							      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel										  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function VendaSintetico(oPanel,aDados,cPerspectiva,cCliente,cLoja)

	Local oFonteSay			:= TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
	Local oFntGroup 		:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local nPanelHeight		:= oPanel:nClientHeight / 2
	Local nPanelWidth		:= oPanel:nClientWidth / 2
	Local nColorSay			:= 0
	Local nLinha	   		:= 5
	Local cClienteDesde		:= ""
	Local cFrota	   		:= ""
	Local cDiasNiver   		:= ""
	Local cComport	   		:= ""
	Local cNomeMes1	   		:= ""
	Local cNomeMes2	   		:= ""
	Local cNomeMes3	   		:= ""
	Local cValMes1			:= ""
	Local cValMes2			:= ""
	Local cValMes3			:= ""
	Local cTotal	   		:= ""
	Local aUltVendas		:= {}
	Local aUltMeses	   		:= {}
	Local aGrafico			:= {}
	Local aComportamento	:= {}
	Local aAniversario		:= {}
	Local nFrota			:= 0
	Local oMes1
	Local oMes2
	Local oMes3
	Local oTotal
	Local cCSSGroup			:= ""

// CSS do objeto group para colorir a borda
	cCSSGroup := " QGroupBox { "
	cCSSGroup += " border: 1px solid #000000; "
	cCSSGroup += " padding-top: 0px; "
	cCSSGroup += " } "

	if Empty(aDados)

		aUltVendas 		:= {{"","",CTOD("  /  /    "),0,0,0,0,0,""}}
		aUltMeses  		:= {{"",0},{"",0},{"",0},{"",0}}
		aGrafico		:= {{"",0}}
		aComportamento	:= {{"",0,0}}
		nFrota			:= 0
		cClienteDesde	:= "  /  /    "
		aAniversario	:= {.F.,0}

	else

		aUltVendas 		:= aDados[1]
		aUltMeses  		:= aDados[2]
		aGrafico		:= aDados[3]
		aComportamento	:= aDados[7]
		nFrota			:= aDados[8]
		cClienteDesde	:= DTOC(aDados[9])
		aAniversario	:= aDados[10]

	endif

	cNomeMes1  		:= MesExtenso(Val(aUltMeses[1,1]))
	cNomeMes2  		:= MesExtenso(Val(aUltMeses[2,1]))
	cNomeMes3  		:= MesExtenso(Val(aUltMeses[3,1]))
	cComport   		:= aComportamento[1,1]
	cValMes1   		:= AllTrim(Transform(aUltMeses[1,2] , "@E 999,999,999.99"))
	cValMes2		:= AllTrim(Transform(aUltMeses[2,2] , "@E 999,999,999.99"))
	cValMes3   		:= AllTrim(Transform(aUltMeses[3,2] , "@E 999,999,999.99"))
	cTotal			:= AllTrim(Transform(aUltMeses[4,2] , "@E 999,999,999.99"))
	cFrota			:= AllTrim(Transform( , "@E 999,999,999"))

	if aAniversario[1] .OR. aAniversario[2] > 0
		cDiasNiver := iif(aAniversario[1] , "Parabéns, hoje é o seu aniversário!" , "Faltam " + AllTrim(Transform(aAniversario[2] , "@E 999,999,999")) + " dias para seu aniversário!" )
	endif

	if cPerspectiva == "GRUPO" .OR. cPerspectiva == "CLIENTE"

		@ nLinha , 005 SAY oSay1 PROMPT "Cliente desde:  " + AllTrim(cClienteDesde)  SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

		@ nLinha , 175 SAY oSay1 PROMPT "Frota:  " + AllTrim(cFrota) + " veículos" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	endif

	if cPerspectiva == "MOTORISTA"

		@ nLinha , 005 SAY oSay1 PROMPT cDiasNiver SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	endif

	nLinha += 15

	@ nLinha, 005 GROUP oGroup1 TO nLinha + 1 , 470 PROMPT "" OF oPanel PIXEL
	oGroup1:SetCss(cCSSGroup)

	nLinha += 10

	@ nLinha , 005 SAY oSay1 PROMPT "Últimas vendas:" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	nLinha += 15

// chamo grid para visualização das vendas
	oGridVendas := GridVendas(oPanel,nLinha,aUltVendas)

	nLinha += 110

	@ nLinha , 005 SAY oSay1 PROMPT "Últimas vendas em litros:" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	@ nLinha , 125 SAY oSay1 PROMPT cComport SIZE 150, 015 OF oPanel FONT oFonteSay COLORS 255, 14803425 PIXEL

	nLinha += 15

	@ nLinha, 005 GROUP oGroup1 TO nLinha + 30,100 PROMPT " " + cNomeMes1 + " " OF oPanel PIXEL
	oGroup1:oFont := oFntGroup
	oGroup1:SetCss(cCSSGroup)

	@ nLinha + 13 , 010 SAY oMes1 PROMPT cValMes1 SIZE 090, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	@ nLinha, 105 GROUP oGroup2 TO nLinha + 30,200 PROMPT " " + cNomeMes2 + " " OF oPanel PIXEL
	oGroup2:oFont := oFntGroup
	oGroup2:SetCss(cCSSGroup)

	@ nLinha + 13 , 110 SAY oMes2 PROMPT cValMes2 SIZE 090, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	@ nLinha, 205 GROUP oGroup3 TO nLinha + 30,300 PROMPT " " + cNomeMes3 + " " OF oPanel PIXEL
	oGroup3:oFont := oFntGroup
	oGroup3:SetCss(cCSSGroup)

	@ nLinha + 13 , 210 SAY oMes3 PROMPT cValMes3 SIZE 090, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	@ nLinha, 305 GROUP oGroup4 TO nLinha + 30,400 PROMPT " Total " OF oPanel PIXEL
	oGroup4:oFont := oFntGroup
	oGroup4:SetCss(cCSSGroup)

	@ nLinha + 13 , 310 SAY oTotal PROMPT cTotal SIZE 090, 010 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 30

	oGrafVendas := GraficoVendas(oPanel,nLinha,190,405,aGrafico)

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ GridVendas ºAutor ³ Wellington Gonçalves º Data ³11/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o grid de vendas				          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function GridVendas(oPanel,nLinha,aDados)

	Local oGrid
	Local aFields 	:= {"X5_DESCRI","L1_EMISSAO","L2_DESCRI","L2_QUANT","L2_VRUNIT","L2_VLRITEM","L1_TROCO1","PERCENTUAL","L1_FILIAL"}
	Local aHeader	:= {}
	Local aItens	:= {}
	Local aAlterFields 	:= {}
	Local aColsSize := {{"X5_DESCRI ",30}}
	Local nX := 0

	For nX := 1 to Len(aFields)

		if AllTrim(aFields[nX]) == "PERCENTUAL"
			Aadd(aHeader, {"% Troco",'PERCENTUAL','@E 99999.99',8,2,'','€€€€€€€€€€€€€€','N','','','',''})
		else

			if AllTrim(aFields[nX]) == "X5_DESCRI"
				Aadd(aHeader, U_UAHEADER(aFields[nX]))
				aHeader[Len(aHeader)][01] := "Forma de Pgto"
			else
				Aadd(aHeader, U_UAHEADER(aFields[nX]))
			endif

		endif

	Next nX

	For nX := 1 To Len(aDados)
		aadd(aItens,{aDados[nX,1],aDados[nX,3],aDados[nX,2],aDados[nX,4],aDados[nX,5],aDados[nX,6],aDados[nX,7],aDados[nX,8],aDados[nX,9],.F.})
	Next nX

// crio o grid de vendas
//oGrid := GRIDPOSTO():New(nLinha,005,467,100,oPanel,aHeader,aItens,2)
	oGrid := MsNewGetDados():New( nLinha, 005, 1.5*100, 467,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 9999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aHeader, aItens,,,aColsSize)

// retiro a barra de rolagem vertical
	oGrid:oBrowse:LHSCROLL := .F.

Return(oGrid)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ GraficoVendas ºAutor³ Wellington Gonçalves ºData³11/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o gráfico de vendas				          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function GraficoVendas(oPanel,nLinha,nAltura,nLargura,aDados)

	Local oGraphic
	Local oFonteGrafic := TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
	Local nColorMenor	:= 255
	Local nColorMaior	:= 11623431
	Local nColorGeral	:= 16296540
	Local nX			:= 0
	Local aAux			:= {}
	Local nPos			:= 0
	Local aAux2			:= {}
	Local lCreateSerie3	:= .F.
	Local nSerie1
	Local nSerie2
	Local nSerie3

// crio o objeto do gráfico
	oGraphic := TMSGraphic():New( nLinha,001,oPanel,,,RGB(0,0,0),nLargura,nAltura)

// defino as margens do gráfico
	oGraphic:SetMargins(10,10,10,10)

// defino o título do gráfico
	oGraphic:SetTitle("               Compras do cliente (30 dias)", "", CLR_HRED, A_CENTER , GRP_TITLE )

// defino a legenda do gráfico
	oGraphic:SetLegenProp(GRP_SCRRIGHT, CLR_WHITE, GRP_AUTO, .F.)

// se não existe consumo em nenhuma filial
	if Len(aDados) > 0

		aAux := ASort(aClone(aDados),,,{|x,y| x[2] > y[2]})

		aadd(aAux2,{ aAux[1,1] , aAux[1,2] }) // filial com o maior consumo

		if Len(aAux) > 1

			aadd(aAux2,{ aAux[Len(aAux),1] , aAux[Len(aAux),2] }) // filial com o menor consumo

			if Len(aAux) > 2

				// demais filiais
				For nX := 2 To Len(aAux) - 1

					aadd(aAux2,{ aAux[nX,1] , aAux[nX,2] })

				Next nX

			endif

		endif

		// crio a série
		nSerie := oGraphic:CreateSerie( GRP_BAR , "" )

		For nX := 1  To Len(aAux2)

			// oGraphic:Add(nSerie, aAux2[nX,2] , aAux2[nX,1] + " - " + AllTrim(Posicione('SM0',1,cEmpAnt + aAux2[nX,1],'M0_FILIAL')) , nColorGeral )
			oGraphic:Add(nSerie, aAux2[nX,2] , aAux2[nX,1] , nColorGeral )

		Next nX

	endif

Return(oGraphic)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ VendaAnaliticoºAutor³ Wellington Gonçalves ºData³14/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Histórico de vendas analitico						      º±±
±±º          ³ 							                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParam.    ³ 1 - Objeto do painel										  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function VendaAnalitico(oPanel,aDados,cPerspectiva,cCliente,cLoja)

	Local oFonteSay	   		:= TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
	Local oFonteSayN   		:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local oFntGroup    		:= TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local nPanelHeight		:= oPanel:nClientHeight / 2
	Local nPanelWidth  		:= oPanel:nClientWidth / 2
	Local nColorSay			:= 0
	Local nLinha			:= 5
	Local cClienteDesde		:= ""
	Local cFrota			:= ""
	Local cDiasNiver		:= ""
	Local cComport	   		:= "Volume em queda!"
	Local cNomeMes1	   		:= ""
	Local cNomeMes2			:= ""
	Local cNomeMes3			:= ""
	Local cValMes1			:= ""
	Local cValMes2			:= ""
	Local cValMes3			:= ""
	Local cTotVendLT		:= "0"
	Local cTotVendRS		:= "0"
	Local cNomeTopMes		:= ""
	Local cValTopMes		:= "0"
	Local cNomeMenMes		:= ""
	Local cValMenMes		:= "0"
	Local cComport			:= ""
	Local aUltVendas   		:= {}
	Local aUltMeses			:= {}
	Local aGrafico			:= {}
	Local aTotalVendas		:= {}
	Local aMelhorMes		:= {}
	Local aFilMenor	   		:= {}
	Local aComportamento	:= {}
	Local aAniversario		:= {}
	Local nFrota			:= 0
	Local oMes1
	Local oMes2
	Local oMes3
	Local cCSSGroup			:= ""

// CSS do objeto group para colorir a borda
	cCSSGroup := " QGroupBox { "
	cCSSGroup += " border: 1px solid #000000; "
	cCSSGroup += " padding-top: 0px; "
	cCSSGroup += " } "

	if Empty(aDados)

		aUltVendas 		:= {{"","",CTOD("  /  /    "),0,0,0,0,0,""}}
		aUltMeses  		:= {{"",0},{"",0},{"",0},{"",0}}
		aGrafico		:= {{"",0}}
		aTotalVendas	:= {{0,0}}
		aMelhorMes		:= {{"",0}}
		aFilMenor		:= {{"",0}}
		aComportamento	:= {{"",0,0}}
		nFrota			:= 0
		cClienteDesde	:= "  /  /    "
		aAniversario	:= {.F.,0}

	else

		aUltVendas 		:= aDados[1]
		aUltMeses		:= aDados[2]
		aGrafico		:= aDados[3]
		aTotalVendas	:= aDados[4]
		aMelhorMes		:= aDados[5]
		aFilMenor		:= aDados[6]
		aComportamento	:= aDados[7]
		nFrota			:= aDados[8]
		cClienteDesde	:= DTOC(aDados[9])
		aAniversario	:= aDados[10]

	endif

	cNomeMes1  		:= MesExtenso(Val(aUltMeses[1,1]))
	cNomeMes2  		:= MesExtenso(Val(aUltMeses[2,1]))
	cNomeMes3  		:= MesExtenso(Val(aUltMeses[3,1]))
	cComport		:= aComportamento[1,1]
	cValMes1   		:= AllTrim(Transform(aUltMeses[1,2] , "@E 999,999,999.99"))
	cValMes2   		:= AllTrim(Transform(aUltMeses[2,2] , "@E 999,999,999.99"))
	cValMes3		:= AllTrim(Transform(aUltMeses[3,2] , "@E 999,999,999.99"))

	cTotVendLT 		:= AllTrim(Transform(aTotalVendas[1,1] , "@E 999,999,999.99"))
	cTotVendRS 		:= AllTrim(Transform(aTotalVendas[1,2] , "@E 999,999,999.99"))

	cNomeTopMes		:= AllTrim(aMelhorMes[1,1])
	cValTopMes		:= AllTrim(Transform(aMelhorMes[1,2] , "@E 999,999,999.99"))

	cNomeMenMes		:= AllTrim(Posicione('SM0',1,cEmpAnt + aFilMenor[1,1],'M0_FILIAL'))
	cValMenMes 		:= AllTrim(Transform(aFilMenor[1,2] , "@E 999,999,999.99"))

	cFrota			:= AllTrim(Transform(nFrota , "@E 999,999,999"))

	if aAniversario[1] .OR. aAniversario[2] > 0
		cDiasNiver := iif(aAniversario[1] , "Parabéns, hoje é o seu aniversário!" , "Faltam " + AllTrim(Transform(aAniversario[2] , "@E 999,999,999")) + " dias para seu aniversário!" )
	endif

	if cPerspectiva == "GRUPO" .OR. cPerspectiva == "CLIENTE"

		@ nLinha , 005 SAY oSay1 PROMPT "Cliente desde:  " + AllTrim(cClienteDesde)  SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL
		@ nLinha , 175 SAY oSay1 PROMPT "Frota:  " + AllTrim(cFrota) + " veículo(os)" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	endif

	if cPerspectiva == "MOTORISTA"

		@ nLinha , 005 SAY oSay1 PROMPT cDiasNiver SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	endif

	nLinha += 15

	@ nLinha, 005 GROUP oGroup1 TO nLinha + 1 , 470 PROMPT "" OF oPanel COLOR 0, 16777215 PIXEL
	oGroup1:SetCss(cCSSGroup)

	nLinha += 10

	@ nLinha , 005 SAY oSay1 PROMPT "Últimas vendas:" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	nLinha += 15

// chamo grid para visualização dos limites de crédito
	oGridVendas := GridVendas(oPanel,nLinha,aUltVendas)

	nLinha += 110

	@ nLinha, 005 GROUP oGroup2 TO nLinha + 1 , 470 PROMPT "" OF oPanel PIXEL
	oGroup2:SetCss(cCSSGroup)

	nLinha += 5

	@ nLinha , 005 SAY oSay1 PROMPT "Total de vendas de combustível" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 175 SAY oSay2 PROMPT cTotVendLT + " Lt's" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 300 SAY oSay3 PROMPT "R$ " + cTotVendRS SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 15

	@ nLinha , 005 SAY oSay4 PROMPT "Mês de maior consumo de combustível" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 175 SAY oSay5 PROMPT cNomeTopMes SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 300 SAY oSay6 PROMPT cValTopMes + " Lt's" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 15

	@ nLinha , 005 SAY oSay7 PROMPT "Filial com menor consumo (90 dias)" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 175 SAY oSay8 PROMPT cNomeMenMes SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER
	@ nLinha , 300 SAY oSay9 PROMPT cValMenMes + " Lt's" SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL CENTER

	nLinha += 20

	@ nLinha, 005 GROUP oGroup3 TO nLinha + 1 , 470 PROMPT "" OF oPanel PIXEL
	oGroup3:SetCss(cCSSGroup)

	nLinha += 5

	oGrafVendas := GraficoVendas(oPanel,nLinha,175,310,aGrafico)

	nLinha += 5

	@ nLinha, 320 GROUP oGroup3 TO nLinha + 085 , 470 PROMPT " Últimas vendas mensais (Lt's) " OF oPanel PIXEL
	oGroup3:oFont := oFntGroup
	oGroup3:SetCss(cCSSGroup)

	nLinha += 15

	@ nLinha , 330 SAY oSay1 PROMPT cNomeMes1 + ": " SIZE 060, 015 OF oPanel FONT oFonteSayN PIXEL RIGHT
	@ nLinha , 390 SAY oMes1 PROMPT cValMes1 SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	nLinha += 15

	@ nLinha , 330 SAY oSay7 PROMPT cNomeMes2 + ": " SIZE 060, 015 OF oPanel FONT oFonteSayN PIXEL RIGHT
	@ nLinha , 390 SAY oMes2 PROMPT cValMes2 SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	nLinha += 15

	@ nLinha , 330 SAY oSay7 PROMPT cNomeMes3 + ": " SIZE 060, 015 OF oPanel FONT oFonteSayN PIXEL RIGHT
	@ nLinha , 390 SAY oMes3 PROMPT cValMes3 SIZE 200, 015 OF oPanel FONT oFonteSay PIXEL

	nLinha += 20

	@ nLinha , 295 SAY oSay7 PROMPT cComport SIZE 200, 015 OF oPanel FONT oFonteSayN COLORS 255, 14803425 PIXEL CENTER

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ GridFiliais º Autor ³ Wellington Gonçalves ºData³16/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o grid de filiais				          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function GridFiliais(oPanel,nLinha,aFiliais)

	Local oGrid
	Local aHeader		:= {}
	Local aItens		:= {}
	Local oOK			:= LoadBitmap(GetResources(),"CHECKED")
	Local oNO			:= LoadBitmap(GetResources(),"UNCHECKED")
	Local o2	   		:= LoadBitmap(GetResources(),"OK")
	Local nPanelHeight	:= oPanel:nClientHeight / 2
	Local nX			:= 0
	Local aDados		:= aClone(aFiliais)
	Local aAlterFields 	:= {}
	Local aColsSize := {{"MARK",10},{"CODIGO",30},{"NOME",100},{"CIDADE",100}}

	Aadd(aHeader, {"",'MARK','@BMP',30,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aHeader, {"Código",'CODIGO','@!',30,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aHeader, {"Nome",'NOME','@!',100,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aHeader, {"Cidade",'CIDADE','@!',100,0,'','€€€€€€€€€€€€€€','C','','','',''})

	For nX := 1 To Len(aDados)
		if aDados[nX,1] == "OK"
			aDados[nX,1] := oOK
		else
			aDados[nX,1] := oNO
		endif
		aadd(aItens,{aDados[nX,1],aDados[nX,2],aDados[nX,3],aDados[nX,4],.F.})
	Next nX

//oGrid := GRIDPOSTO():New(nLinha,005,467,nPanelHeight - nLinha - 28  /*140*/,oPanel,aHeader,aItens,1)
	oGrid := MsNewGetDados():New( nLinha, 005, 1.3*(nPanelHeight - nLinha - 28), 467,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 9999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aHeader, aItens,,,aColsSize)

// retiro a barra de rolagem vertical
	oGrid:oBrowse:LHSCROLL := .F.

Return(oGrid)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ GridPrecos º Autor ³ Wellington Gonçalves º Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que monta o grid de preços				          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function GridPrecos(oPanel,nLinha,aDados)

	Local oGrid
	Local aFields		:= {"VIGENCIA","U25_FILIAL","U25_DESFPG","U25_DESCPG","U25_PRODUT","U25_DESPRO","U25_PRCVEN"}
	Local aHeader		:= {}
	Local aItens		:= {}
	Local nPanelHeight	:= oPanel:nClientHeight / 2
	Local oOK			:= LoadBitmap(GetResources(),"OK")
	Local oNO			:= LoadBitmap(GetResources(),"CANCEL")
	Local oStatus
	Local aAlterFields 	:= {}
	Local nX := 0

	If U25->(FieldPos("U25_DESPBA"))>0
		aFields	:= {"VIGENCIA","U25_FILIAL","U25_DESFPG","U25_DESCPG","U25_PRODUT","U25_DESPRO","U25_PRCBAS","U25_PRCVEN","U25_DESPBA"}
	EndIf

	For nX := 1 to Len(aFields)
		If AllTrim(aFields[nX]) == "VIGENCIA"
			Aadd(aHeader, {"",'VIGENCIA','@BMP',30,0,'','€€€€€€€€€€€€€€','C','','','',''} )
		Else
			Aadd(aHeader, U_UAHEADER(aFields[nX]))
		EndIf
	Next nX

	For nX := 1 To Len(aDados)
		// aPrecos - [01]-FILIAL,[02]-FORMA,[03]-CONDICAO,[04]-PRODUTO,[05]-DESCRICAO,[06]-PRC BASE,[07]-PRC VENDA,[08]-DESC/ACRES,[09]-DT VIGENCIA,[10]-HR VIGENCIA
		// aPrecos - [01]-FILIAL,[02]-FORMA,[03]-CONDICAO,[04]-PRODUTO,[05]-DESCRICAO,[06]-PRC VENDA,[07]-DT VIGENCIA,[08]-HR VIGENCIA
		If U25->(FieldPos("U25_DESPBA"))>0
			If Empty(aDados[nX,09]) .OR. aDados[nX,09] > dDataBase
				oStatus := oOK
			ElseIf aDados[nX,09] == dDataBase
				If aDados[nX,10] < SubStr(Time(),1,5)
					oStatus := oOK
				Else
					oStatus := oNO
				EndIf
			Else
				oStatus := oNO
			EndIf
			aadd(aItens,{oStatus,aDados[nX,1],aDados[nX,2],aDados[nX,3],aDados[nX,4],aDados[nX,5],aDados[nX,6],aDados[nX,7],aDados[nX,8],.F.})
		Else
			If Empty(aDados[nX,7]) .OR. aDados[nX,7] > dDataBase
				oStatus := oOK
			ElseIf aDados[nX,7] == dDataBase
				If aDados[nX,8] < SubStr(Time(),1,5)
					oStatus := oOK
				Else
					oStatus := oNO
				EndIf
			Else
				oStatus := oNO
			EndIf
			aadd(aItens,{oStatus,aDados[nX,1],aDados[nX,2],aDados[nX,3],aDados[nX,4],aDados[nX,5],aDados[nX,6],.F.})
		EndIf
	Next nX

// ordeno o array pela vigencia + filial + descrição da forma de pagamento + produto
	If Len(aItens) > 0
		aItens := ASort(aClone(aItens),,,{|x,y| x[1]:cName + x[2] + x[3] + x[5] > y[1]:cName + y[2] + y[3] + y[5] })
	EndIf

	nWidth  := oPanel:nWidth/2
	nHeight := oPanel:nHeight/2

//oGrid := GRIDPOSTO():New(nLinha,005,nWidth-5,nPanelHeight-nLinha-5 /*140*/,oPanel,aHeader,aItens,1)
	oGrid := MsNewGetDados():New( nLinha, 005, 1.3*(nPanelHeight-nLinha-5), nWidth-5,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 99999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aHeader, aItens)

// retiro a barra de rolagem vertical
	oGrid:oBrowse:LHSCROLL := .F.

Return(oGrid)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ BuscaDados º Autor ³ Wellington Gonçalves º Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que busca os dados na retaguarda			          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function BuscaDados(cAmbiente,aHistVenda,aHistCredito,aPrecos,aFiliais,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva)

	Local oRpcSrv
	Local cRpcIP 	:= ""
	Local nRpcPorta := 0
	Local cRpcEnv	:= ""
	Local cRpcEmp	:= cEmpAnt
	Local cRpcFil	:= cFilAnt
	Local cAmbLocal := AllTrim( SuperGetMV("MV_LJAMBIE",,"") )
	Local aDados	:= {}

	if cAmbiente == "1" // Retaguarda (BASE TOP)

		aDados := U_TRETA41A(cAmbiente,aHistVenda,aHistCredito,aPrecos,@aFiliais,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva)

	elseif cAmbiente == "2" // PDV (BASE DBF)

		//Conout( ">> RPC PARA CONSULTA DO HISTÓRICO DE VENDAS")

		If !Empty( cAmbLocal )

			// posiciono na tabela de configuração de ambiente
			MD4->(DbSetOrder(1)) // MD4_FILIAL + MD4_CODIGO

			If MD4->(DbSeek( xFilial("MD4") + cAmbLocal ))

				MD3->(DbSetOrder(1)) // MD3_FILIAL + MD3_CODAMB + MD3_TIPO

				If MD3->(DbSeek( xFilial( "MD3" ) + MD4->MD4_AMBPAI + "R")) //"R" -> Tipo de Cominicacao RPC

					cRpcEnv 	:= AllTrim( MD3->MD3_NOMAMB )
					cRpcEmp 	:= AllTrim( MD3->MD3_EMP )
					cRpcFil 	:= cFilAnt //AllTrim( MD3->MD3_FIL )
					cRpcIP  	:= AllTrim( MD3->MD3_IP )
					nRpcPorta 	:= Val( MD3->MD3_PORTA )

					oRpcSrv := TRpc():New(cRpcEnv)

					If ( oRpcSrv:Connect( cRpcIP, nRpcPorta ) )

						//Conout( ">> CONEXAO RPC ESTABELECIDA COM O SERVIDOR - " + cRpcIP + " PORTA - " + cValToChar(nRpcPorta))

						// Seto a empresa e filial logada
						// oRpcSrv:CallProc('RpcSetType',3)
						// lConect := oRpcSrv:CallProc('RpcSetEnv',cRpcEmp,cRpcFil)

						// Executa função através do CallProc
						aDados := oRpcSrv:CallProc( 'U_TRETA41A',cAmbiente,aHistVenda,aHistCredito,aPrecos,aFiliais,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,.T.,cRpcEmp,cRpcFil)

						if !Empty(aDados) .AND. aDados[5]

							//Conout(">> EMPRESA: " + cEmpAnt)
							//Conout(">> FILIAL: " + cFilAnt)

						else
							//Conout(">> NAO FOI POSSIVEL CONECTAR NA EMPRESA " + cRpcEmp + " FILIAL " + cRpcFil)
						endif

						// Desconecta do servidor
						oRpcSrv:Disconnect()

					Else
						//Conout( ">> NAO FOI POSSIVEL CONECTAR NO SERVIDOR - " + cRpcIP + " PORTA - " + cValToChar(nRpcPorta))
					Endif

				endif

			endif

		endif

		if Empty(aDados)

			aHistVenda 		:= {}
			aHistCredito	:= {}
			aPrecos 		:= {}
			aFiliais		:= {}

		else

			aHistVenda 		:= aDados[1]
			aHistCredito	:= aDados[2]
			aPrecos 		:= aDados[3]
			aFiliais		:= aDados[4]

		endif

	endif

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ TRETA41A º Autor ³Wellington Gonçalvesº Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que chama as funções para realizar as consultas SQL º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function TRETA41A(cAmbiente,aHistVenda,aHistCredito,aPrecos,aFiliais,cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,lLicenca,cEmp,cFil)

	Local aRet 			:= {}
	Local lConnect		:= .T.
	Default cEmp		:= ""
	Default cFil		:= ""
	Default lLicenca	:= .F.

	if lLicenca

		// Não utilizar licença
		RpcSetType(3)
		Reset Environment
		lConnect := RpcSetEnv(cEmp,cFil)

	endif

	if lConnect

		// consulta as filiais
		if Empty(aFiliais)
			aFiliais := BuscaFiliais()
		endif

		// consulta os dados do histórico de vendas
		aHistVenda := BuscaHistVend(cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais)

		// consulta os dados do histórico de crédito
		aHistCredito := BuscaHistCredito(cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais)

		// consulta os dados de preço
		aPrecos := BuscaPreco(cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais)

	endif

Return({aHistVenda,aHistCredito,aPrecos,aFiliais,lConnect})

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ BuscaHistVendº Autor ³Wellington Gonçalvesº Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Consulta SQL do histórico de vendas						  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function BuscaHistVend(cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais)

	Local cQry 		   		:= ""
	Local cFormas	   		:= ""
	Local cComportamento	:= ""
	Local aDados	   		:= {}
	Local aUltVendas   		:= {}
	Local aUltMeses	   		:= {}
	Local aGrafico	   		:= {}
	Local aTotalVendas 		:= {}
	Local aMelhorMes   		:= {}
	Local aFilMenor	   		:= {}
	Local aRet 				:= {}
	Local aComportamento	:= {}
	Local nDiasMenorCon		:= 90
	Local nQtd1		   		:= SuperGetMV("MV_XQTD1",,10) // quantidade de cupons apresentados
	Local nQtd2				:= 03 // quantidade de meses para análise
	Local nQtd3				:= 30 // quantidade de dias para analise de consumo por filial
	Local cFiliais			:= ""
	Local nContFil			:= 0
	Local lTodasFil			:= .F.
	Local dDataInclusao		:= CTOD("  /  /    ")
	Local nQtdFrota			:= 0
	Local nDiasNiver		:= 0
	Local aAniversario		:= {.F.,0}
	Local nX := 0
	Local cMvCombus			:= SuperGetMV("MV_COMBUS")
	Local cMvGRARLA			:= SuperGetMV("MV_XGRARLA",,"")
	Local bGetMvFil	:= {|cParametro,lHelp,cDefault,cFil| SuperGetMV(cParametro,lHelp,cDefault,cFil) }
	Local cSGBD 	 	:= Upper(AllTrim(TcGetDB()))	// Guarda Gerenciador de banco de dados

// converto o array de filiais selecionadas em string para utilizar na consulta SQL
	For nX := 1 To Len(aFiliais)

		if aFiliais[nX,1] == "OK"
			cFiliais += iif(Empty(cFiliais),"",",") + aFiliais[nX,2]
			nContFil += 1
		endif

	Next nX

// verifica se todas as filiais foram selecionadas
	If nContFil == Len(aFiliais)
		lTodasFil := .T.
	EndIf

///////////////////////////////////  ULTIMAS VENDAS  ///////////////////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := " SELECT " 																			+ CRLF
	If "ORACLE" $ cSGBD //Oracle 
	else
		cQry += " TOP " + cValToChar(nQtd1) 													+ CRLF
	endif
	cQry += " SF2.F2_FILIAL FILIAL, " 															+ CRLF
	cQry += " SL1.L1_NUM ORCAMENTO, " 															+ CRLF
	cQry += " SB1.B1_DESC DESCRICAO_PRODUTO, " 													+ CRLF
	cQry += " SD2.D2_EMISSAO EMISSAO, " 														+ CRLF
	cQry += " SD2.D2_QUANT QUANTIDADE, " 														+ CRLF
	cQry += " SD2.D2_PRCVEN VALOR_UNITARIO, " 													+ CRLF
	cQry += " SD2.D2_TOTAL VALOR_TOTAL, " 														+ CRLF
	cQry += " SL1.L1_TROCO1 TROCO, " 															+ CRLF
	cQry += " ROUND( ( SL1.L1_TROCO1 / SF2.F2_VALBRUT ) * 100 ,2) PERCENTUAL_TROCO " 			+ CRLF
	cQry += " FROM " 																			+ CRLF
	cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF

	cQry += " INNER JOIN " 																		+ CRLF
	cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
	cQry += " ON ( "									  										+ CRLF
	cQry += " 	SD2.D2_DOC = SF2.F2_DOC "														+ CRLF
	cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "								  				+ CRLF
	cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "								   			+ CRLF
	cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   												+ CRLF
	cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "												+ CRLF
	cQry += " 	AND SD2.D_E_L_E_T_ <> '*' "									  					+ CRLF
	cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
	cQry += "	AND SF2.F2_TIPO = 'N'"															+ CRLF
	cQry += " 	) "																				+ CRLF

	cQry += " 	INNER JOIN " 																	+ CRLF
	cQry += 	+ RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
	cQry += " 	ON ( "									   										+ CRLF
	cQry += " 		SD2.D2_COD = SB1.B1_COD "									  				+ CRLF
	cQry += " 		AND ( SB1.B1_GRUPO IN "+FormatIN(cMvCombus,"/")					+ CRLF //Combustíveis
	cQry += " 			OR SB1.B1_GRUPO IN "+FormatIN(cMvGRARLA,"/") + " )"			+ CRLF //Arla
	cQry += " 		AND SB1.D_E_L_E_T_ <> '*' "									  				+ CRLF
	cQry += " 		) "									  										+ CRLF

	cQry += " INNER JOIN " 																		+ CRLF
	cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
	cQry += " ON ( "									  										+ CRLF
	cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
	cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
	cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
	cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
	cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF
	cQry += " 	) "	 																			+ CRLF

	cQry += " INNER JOIN " 																		+ CRLF
	cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
	cQry += " ON ( "									  										+ CRLF
	cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "									   				+ CRLF
	cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 							 					+ CRLF
	cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "														+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "					  					+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "					  					+ CRLF
		cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "						  					+ CRLF
	endif

	cQry += " 	) "																				+ CRLF

	cQry += " WHERE "									  										+ CRLF
	cQry += " SF2.D_E_L_E_T_ <> '*' " 							  								+ CRLF

	if !Empty(cFiliais) .And. !lTodasFil
		cQry += " AND SF2.F2_FILIAL IN " + FormatIn(cFiliais,",") 	  							+ CRLF
	endif

	if cPerspectiva == "MOTORISTA"
		if SL1->(FieldPos("L1_CGCMOTO")) > 0
			cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "				  					+ CRLF
		else
			cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "				  					+ CRLF
		endif
	endif

	if cPerspectiva == "PLACA"
		cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "		 			  					+ CRLF
	endif

	If "ORACLE" $ cSGBD //Oracle 
		cQry += " AND ROWNUM <= 1"
	endif
	cQry += " ORDER BY SF2.F2_EMISSAO DESC , SF2.F2_DOC, SF2.F2_SERIE "				   	  		+ CRLF

	cQry := ChangeQuery(cQry)
	
	// executo a query e crio o alias temporario
	MPSysOpenQuery( cQry, 'QRY' )

	While QRY->(!Eof())

		cFormas := ""

		SL4->(DbSetOrder(1)) // L4_FILIAL + L4_NUM
		if SL4->(DbSeek(QRY->FILIAL + QRY->ORCAMENTO))

			While SL4->(!Eof()) .AND. SL4->L4_FILIAL == QRY->FILIAL .AND. SL4->L4_NUM == QRY->ORCAMENTO

				cFormas += AllTrim(Posicione("SX5",1,xFilial("SX5") + "24" + AllTrim(SL4->L4_FORMA) , "X5_DESCRI" )) + " / "
				SL4->(DbSkip())

			EndDo

			cFormas := SubStr(cFormas,1,Len(cFormas) - 2)

		endif

		aDados := {}
		aadd(aDados,cFormas)
		aadd(aDados,QRY->DESCRICAO_PRODUTO)
		aadd(aDados,STOD(QRY->EMISSAO))
		aadd(aDados,QRY->QUANTIDADE)
		aadd(aDados,QRY->VALOR_UNITARIO)
		aadd(aDados,QRY->VALOR_TOTAL)
		aadd(aDados,QRY->TROCO)
		aadd(aDados,QRY->PERCENTUAL_TROCO)
		aadd(aDados,QRY->FILIAL)
		aadd(aUltVendas,aDados)

		QRY->(DbSkip())

	EndDo

///////////////////////////////////  ULTIMAS VENDAS EM LITROS  ///////////////////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := ""

	For nX := 1 To nQtd2

		cQry += " SELECT " 																			  		+ CRLF
		cQry += " '" + PADL(cValToChar(MONTH(MonthSub(dDataBase,nX - 1))),2,"0") + "' AS MES, "		  		+ CRLF
		cQry += " SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) AS QUANTIDADE "					  	  		+ CRLF
		cQry += " FROM " 																		  	  		+ CRLF
		cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											   	  		+ CRLF

		cQry += " INNER JOIN " 																  				+ CRLF
		cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										 				+ CRLF
		cQry += " ON ( "									   									   			+ CRLF
		cQry += " 	SD2.D2_COD = SB1.B1_COD "									  			   				+ CRLF
		cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  			  				+ CRLF
		cQry += " 	AND ( SB1.B1_GRUPO IN "+FormatIN(cMvCombus,"/")								+ CRLF //Combustíveis
		cQry += " 		OR SB1.B1_GRUPO IN "+FormatIN(cMvGRARLA,"/") + " )"						+ CRLF //Arla
		cQry += " 	) "									  									  				+ CRLF

		cQry += " INNER JOIN " 																  				+ CRLF
		cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+"" 										 				+ CRLF
		cQry += " ON ( "									   									   			+ CRLF
		cQry += " 	SD2.D2_DOC = SF2.F2_DOC "											   			  		+ CRLF
		cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "								  		 		 		+ CRLF
		cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "								   	  	   			+ CRLF
		cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   										   	  			+ CRLF
		cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "										  	   			+ CRLF
		cQry += " 	AND SF2.D_E_L_E_T_ <> '*' "									  			   		 		+ CRLF
		cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
		cQry += "	AND SF2.F2_TIPO = 'N'"																	+ CRLF
		cQry += " 	) "																						+ CRLF

		cQry += " INNER JOIN " 																				+ CRLF
		cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+"" 										   				+ CRLF
		cQry += " ON ( "									  												+ CRLF
		cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "									   						+ CRLF
		cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 							 				 			+ CRLF
		cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "													 			+ CRLF

		if cPerspectiva == "GRUPO"
			cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "					 		 					+ CRLF
		endif

		if cPerspectiva == "CLIENTE"
			cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "					  							+ CRLF
			cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "						  				 			+ CRLF
		endif

		cQry += " 	) "																			 			+ CRLF

		if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"
			cQry += " INNER JOIN " 																		+ CRLF
			cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
			cQry += " ON ( "									  										+ CRLF
			cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
			cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
			cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
			cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
			cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF
			cQry += " 	) "	 																			+ CRLF
		endif

		cQry += " WHERE "									  										  		+ CRLF
		cQry += " SD2.D_E_L_E_T_ <> '*' " 							  										+ CRLF
		cQry += " AND SUBSTRING(SD2.D2_EMISSAO,1,6) = '" + AnoMes(MonthSub(dDataBase,nX - 1)) + "' "		+ CRLF

		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "				  				  			+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "				  				  			+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "		 			  			   			+ CRLF
		endif

		if !Empty(cFiliais) .And. !lTodasFil
			cQry += " AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  					  				+ CRLF
		endif

		cQry += " UNION " 																					+ CRLF

	Next nX

	cQry += " SELECT " 																			  		+ CRLF
	cQry += " 'TOTAL' AS MES, "																	  		+ CRLF
	cQry += " SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) AS QUANTIDADE "					  	  		+ CRLF
	cQry += " FROM " 																		  	  		+ CRLF
	cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+"" 											   	  		+ CRLF

	cQry += " INNER JOIN " 																  				+ CRLF
	cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										 				+ CRLF
	cQry += " ON ( "									   									   			+ CRLF
	cQry += " 	SD2.D2_COD = SB1.B1_COD "									  			   				+ CRLF
	cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  			  				+ CRLF
	cQry += " 	AND ( SB1.B1_GRUPO IN "+FormatIN(Eval(bGetMvFil,"MV_COMBUS"),"/")								+ CRLF //Combustíveis
	cQry += " 		OR SB1.B1_GRUPO IN "+FormatIN(Eval(bGetMvFil,"MV_XGRARLA",,""),"/") + " )"						+ CRLF //Arla
	cQry += " 	) "									  									  				+ CRLF

	cQry += " INNER JOIN " 																  				+ CRLF
	cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										 				+ CRLF
	cQry += " ON ( "									   									   			+ CRLF
	cQry += " 	SD2.D2_DOC = SF2.F2_DOC "											   			  		+ CRLF
	cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "								  		 		 		+ CRLF
	cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "								   	  	   			+ CRLF
	cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   										   	  			+ CRLF
	cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "										  	   			+ CRLF
	cQry += " 	AND SF2.D_E_L_E_T_ <> '*' "									  			   		 		+ CRLF
	cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
	cQry += "	AND SF2.F2_TIPO = 'N'"																	+ CRLF
	cQry += " 	) "																		 				+ CRLF

	cQry += " INNER JOIN " 																				+ CRLF
	cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										   				+ CRLF
	cQry += " ON ( "									  												+ CRLF
	cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "									   						+ CRLF
	cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 							 				 			+ CRLF
	cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "													 			+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "					 		 					+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "					  							+ CRLF
		cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "						  				 			+ CRLF
	endif

	cQry += " 	) "																		 				+ CRLF

	if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

		cQry += " INNER JOIN " 																		+ CRLF
		cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
		cQry += " ON ( "									  										+ CRLF
		cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
		cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
		cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
		cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
		cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF

		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "				  				  	+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "				  				  	+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "		 			  			   		+ CRLF
		endif

		cQry += " 	) "	 																			+ CRLF

	endif

	cQry += " WHERE "									  										  		+ CRLF
	cQry += " SD2.D_E_L_E_T_ <> '*' " 							  										+ CRLF

	if !Empty(cFiliais) .And. !lTodasFil
		cQry += " AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  					  				+ CRLF
	endif

	cQry += " ORDER BY MES "  																 	  		+ CRLF

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETA041_VENDA_MES.txt",cQry)	
	MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

	if QRY->(!Eof())

		While  QRY->(!Eof())

			aadd(aUltMeses,{QRY->MES,QRY->QUANTIDADE})
			QRY->(DbSkip())

		EndDo

	endif

//////////////////////////  GRAFICO DE CONSUMO  /////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := ""

	For nX := 1 To Len(aFiliais)

		if aFiliais[nX,1] == "OK"

			if !Empty(cQry)
				cQry += " UNION "																														+ CRLF
			endif

			cQry += " SELECT " 																			  										  		+ CRLF
			cQry += " SD2.D2_FILIAL FILIAL, "															  										   		+ CRLF
			cQry += " SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) AS QUANTIDADE "												  	  	   									   		+ CRLF
			cQry += " FROM " 																		  	  	   									   		+ CRLF
			cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											   	  										   		+ CRLF

			cQry += " INNER JOIN " 																  												  		+ CRLF
			cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										 												  		+ CRLF
			cQry += " ON ( "									   									   											  		+ CRLF
			cQry += " 	SD2.D2_COD = SB1.B1_COD "									  			   			   									  		+ CRLF
			cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  			  												  		+ CRLF
			cQry += " 	AND ( SB1.B1_GRUPO IN "+FormatIN(Eval(bGetMvFil,"MV_COMBUS"),"/")																		+ CRLF //Combustíveis
			cQry += " 		OR SB1.B1_GRUPO IN "+FormatIN(Eval(bGetMvFil,"MV_XGRARLA",,""),"/") + " )"																+ CRLF //Arla
			cQry += " 	) "									  									  												 		+ CRLF

			cQry += " INNER JOIN " 																  														+ CRLF
			cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										 			 											+ CRLF
			cQry += " ON ( "									   									   		 											+ CRLF
			cQry += " 	SD2.D2_DOC = SF2.F2_DOC "											   			  	 											+ CRLF
			cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "								  		 		 	  											+ CRLF
			cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "								   	  	   													+ CRLF
			cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   										   	  	 												+ CRLF
			cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "										  	   	  												+ CRLF
			cQry += " 	AND SF2.D_E_L_E_T_ <> '*' "									  			   		 	   											+ CRLF
			cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"								+ CRLF
			cQry += "	AND SF2.F2_TIPO = 'N'"																											+ CRLF
			cQry += " 	) "																		 		 												+ CRLF

			cQry += " INNER JOIN " 																		   												+ CRLF
			cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										   		   												+ CRLF
			cQry += " ON ( "									  										  												+ CRLF
			cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "									   				   												+ CRLF
			cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 							 				 	   												+ CRLF
			cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "													 	   												+ CRLF

			if cPerspectiva == "GRUPO"
				cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "					 		 															+ CRLF
			endif

			if cPerspectiva == "CLIENTE"
				cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "					  					 												+ CRLF
				cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "						  				 		  											+ CRLF
			endif

			cQry += " 	) "																		 	   													+ CRLF

			if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

				cQry += " INNER JOIN " 																		+ CRLF
				cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
				cQry += " ON ( "									  										+ CRLF
				cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
				cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
				cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
				cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
				cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF

				if cPerspectiva == "MOTORISTA"
					if SL1->(FieldPos("L1_CGCMOTO")) > 0
						cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "				  					+ CRLF
					else
						cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "				  					+ CRLF
					endif
				endif

				if cPerspectiva == "PLACA"
					cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "		 			  			   		+ CRLF
				endif

				cQry += " 	) "																				+ CRLF

			endif

			cQry += " WHERE "									  										  	   									 		+ CRLF
			cQry += " SD2.D_E_L_E_T_ <> '*' " 							  																		  		+ CRLF
			cQry += " AND SD2.D2_EMISSAO >= '"+DTOS(dDataBase-nQtd3)+"'"							  													+ CRLF
			//cQry += " AND DATEDIFF(DAY,CAST(SD2.D2_EMISSAO AS DATETIME) , CAST('" + DTOS(dDataBase) + "' AS DATETIME)) <= " + cValToChar(nQtd3)		 	+ CRLF
			cQry += " AND SD2.D2_FILIAL = '" + aFiliais[nX,2] + "' "   																			  		+ CRLF
			cQry += " GROUP BY SD2.D2_FILIAL "																   											+ CRLF

		endif

	Next nX

	If !Empty(cQry)

		cQry := ChangeQuery(cQry)
		
		MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

		if QRY->(!Eof())

			While  QRY->(!Eof())

				aadd(aGrafico,{QRY->FILIAL,QRY->QUANTIDADE})
				QRY->(DbSkip())

			EndDo

		endif
	EndIf

//////////////////////////  TOTAL DE VENDAS EM LITROS E REAIS  /////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := " SELECT " 															+ CRLF
	cQry += " SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) LITROS, "			+ CRLF
	cQry += " SUM(SD2.D2_TOTAL) REAIS "	 										+ CRLF
	cQry += " FROM " 															+ CRLF
	cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+"" 								+ CRLF

	cQry += " INNER JOIN " 														+ CRLF
	cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
	cQry += " ON ( "									   						+ CRLF
	cQry += " 	SD2.D2_COD = SB1.B1_COD "									  	+ CRLF
	cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  	+ CRLF
	cQry += " 	AND ( SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_COMBUS"),"/")			+ CRLF //Combustíveis
	cQry += " 		OR SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_XGRARLA",,""),"/") + " )"	+ CRLF //Arla
	cQry += " 	) "									  							+ CRLF

	cQry += " INNER JOIN " 														+ CRLF
	cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
	cQry += " ON ( "									   						+ CRLF
	cQry += " 	SD2.D2_DOC = SF2.F2_DOC "								  		+ CRLF
	cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "						 		+ CRLF
	cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "							+ CRLF
	cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   								+ CRLF
	cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "								+ CRLF
	cQry += " 	AND SF2.D_E_L_E_T_ <> '*' "								 		+ CRLF
	cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
	cQry += "	AND SF2.F2_TIPO = 'N'"											+ CRLF
	cQry += " 	) "																+ CRLF

	cQry += " INNER JOIN " 														+ CRLF
	cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
	cQry += " ON ( "									  						+ CRLF
	cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "									+ CRLF
	cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 								+ CRLF
	cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "										+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "						+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "						+ CRLF
		cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "							+ CRLF
	endif

	cQry += " 	) "																+ CRLF

	if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

		cQry += " INNER JOIN " 														+ CRLF
		cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
		cQry += " ON ( "									  						+ CRLF
		cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   	+ CRLF
		cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 	+ CRLF
		cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  	+ CRLF
		cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   	+ CRLF
		cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "										+ CRLF


		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "					+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "					+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "		 								+ CRLF
		endif

		cQry += " 	) "	 															+ CRLF

	endif

	cQry += " WHERE "									  						+ CRLF
	cQry += " SD2.D_E_L_E_T_ <> '*' " 							  				+ CRLF

	if !Empty(cFiliais) .And. !lTodasFil
		cQry += " AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  			+ CRLF
	endif

	cQry := ChangeQuery(cQry)
	MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

	if  QRY->(!Eof())
		aadd(aTotalVendas,{QRY->LITROS,QRY->REAIS})
	else
		aadd(aTotalVendas,{0,0})
	endif

//////////////////////////  MES/ANO COM MAIOR VENDA  /////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := " SELECT "
	If "ORACLE" $ cSGBD //Oracle 
		cQry := " TMP.* FROM ( SELECT "
	else
		cQry += " TOP 1 "															+ CRLF
	endif
	cQry += " SUBSTRING(SD2.D2_EMISSAO,1,6) AS MES_ANO, "						+ CRLF
	cQry += " SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) AS LITROS "			+ CRLF
	cQry += " FROM " 															+ CRLF
	cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF

	cQry += " INNER JOIN " 														+ CRLF
	cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
	cQry += " ON ( "									   						+ CRLF
	cQry += " 	SD2.D2_COD = SB1.B1_COD "									  	+ CRLF
	cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  	+ CRLF
	cQry += " 	AND ( SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_COMBUS"),"/")			+ CRLF //Combustíveis
	cQry += " 		OR SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_XGRARLA",,""),"/") + " )"	+ CRLF //Arla
	cQry += " 	) "									  							+ CRLF

	cQry += " INNER JOIN " 														+ CRLF
	cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
	cQry += " ON ( "									   						+ CRLF
	cQry += " 	SD2.D2_DOC = SF2.F2_DOC "										+ CRLF
	cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "								+ CRLF
	cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "							+ CRLF
	cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   								+ CRLF
	cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "								+ CRLF
	cQry += " 	AND SF2.D_E_L_E_T_ <> '*' "									  	+ CRLF
	cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
	cQry += "	AND SF2.F2_TIPO = 'N'"											+ CRLF
	cQry += " 	) "																+ CRLF

	cQry += " INNER JOIN " 														+ CRLF
	cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
	cQry += " ON ( "									  						+ CRLF
	cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "									+ CRLF
	cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 							 	+ CRLF
	cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "										+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "						+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "						+ CRLF
		cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "							+ CRLF
	endif

	cQry += " 	) "																+ CRLF

	if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

		cQry += " INNER JOIN " 														+ CRLF
		cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								+ CRLF
		cQry += " ON ( "									  						+ CRLF
		cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   	+ CRLF
		cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 	+ CRLF
		cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  	+ CRLF
		cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   	+ CRLF
		cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "										+ CRLF

		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "					+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "					+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "		 								+ CRLF
		endif

		cQry += " 	) "	 															+ CRLF

	endif

	cQry += " WHERE "									  						+ CRLF
	cQry += " SD2.D_E_L_E_T_ <> '*' " 							  				+ CRLF

	if !Empty(cFiliais) .And. !lTodasFil
		cQry += " AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  			+ CRLF
	endif

	cQry += " GROUP BY SUBSTRING(SD2.D2_EMISSAO,1,6) "		 					+ CRLF
	cQry += " ORDER BY LITROS DESC "		 									+ CRLF

	If "ORACLE" $ cSGBD //Oracle 
		cQry += " ) TMP WHERE ROWNUM <= 1"
	endif

	cQry := ChangeQuery(cQry)
	MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

	if  QRY->(!Eof())
		aadd(aMelhorMes,{MesExtenso(Val(SubStr(QRY->MES_ANO,5,2))) + " / " + SubStr(QRY->MES_ANO,1,4),QRY->LITROS})
	else
		aadd(aMelhorMes,{"",0})
	endif

//////////////////////////  FILIAL DE MENOR CONSUMO EM X DIAS  /////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := " SELECT "
	If "ORACLE" $ cSGBD //Oracle 
		cQry := " TMP.* FROM ( SELECT "
	else
		cQry += " TOP 1 "																			  													+ CRLF
	endif
	cQry += " SD2.D2_FILIAL AS FILIAL, " 														  													+ CRLF
	cQry += " SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) AS LITROS "		   				  	  													+ CRLF
	cQry += " FROM " 																		  	  													+ CRLF
	cQry += + RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											   	  													+ CRLF

	cQry += " INNER JOIN " 																  															+ CRLF
	cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										 															+ CRLF
	cQry += " ON ( "									   									   														+ CRLF
	cQry += " 	SD2.D2_COD = SB1.B1_COD "									  			   															+ CRLF
	cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  			  															+ CRLF
	cQry += " 	AND ( SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_COMBUS"),"/")																			+ CRLF //Combustíveis
	cQry += " 		OR SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_XGRARLA",,""),"/") + " )"																	+ CRLF //Arla
	cQry += " 	) "									  									  															+ CRLF

	cQry += " INNER JOIN " 													  																		+ CRLF
	cQry += + RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""							  																		+ CRLF
	cQry += " ON ( "									   				  																			+ CRLF
	cQry += " 	SD2.D2_DOC = SF2.F2_DOC "								   																			+ CRLF
	cQry += " 	AND SD2.D2_SERIE = SF2.F2_SERIE "																									+ CRLF
	cQry += " 	AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "					 																			+ CRLF
	cQry += " 	AND SD2.D2_LOJA = SF2.F2_LOJA "   						 																			+ CRLF
	cQry += " 	AND SD2.D2_FILIAL = SF2.F2_FILIAL "							  																		+ CRLF
	cQry += " 	AND SF2.D_E_L_E_T_ <> '*' "									  																		+ CRLF
	cQry += " 	AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"									+ CRLF
	cQry += "	AND SF2.F2_TIPO = 'N'"																												+ CRLF
	cQry += " 	) "																																	+ CRLF

	cQry += " INNER JOIN " 											   																				+ CRLF
	cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""							 																		+ CRLF
	cQry += " ON ( "									  					 																		+ CRLF
	cQry += " 	SF2.F2_CLIENTE = SA1.A1_COD "								  																		+ CRLF
	cQry += " 	AND SF2.F2_LOJA = SA1.A1_LOJA "	 							 																		+ CRLF
	cQry += " 	AND SA1.D_E_L_E_T_ <> '*' "								  																			+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += " 	AND SA1.A1_GRPVEN = '" + cGrupo + "' "				   																			+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 	AND SA1.A1_COD = '" + cCliente + "' "					   																		+ CRLF
		cQry += " 	AND SA1.A1_LOJA = '" + cLoja + "' "						 																		+ CRLF
	endif

	cQry += " 	) "												 		   																			+ CRLF

	if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

		cQry += " INNER JOIN " 																		+ CRLF
		cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
		cQry += " ON ( "									  										+ CRLF
		cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
		cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
		cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
		cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
		cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF

		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "					+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "					+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "										+ CRLF
		endif

		cQry += " 	) "	 																			+ CRLF

	endif

	cQry += " WHERE "									  										  													+ CRLF
	cQry += " SD2.D_E_L_E_T_ <> '*' " 							  																					+ CRLF
	cQry += " AND SD2.D2_EMISSAO >= '"+DTOS(dDataBase-nDiasMenorCon)+"'"							  												+ CRLF
	//cQry += " AND DATEDIFF(DAY,CAST(SD2.D2_EMISSAO AS DATETIME) , CAST('" + DTOS(dDataBase) + "' AS DATETIME)) <= " + cValToChar(nDiasMenorCon) 	+ CRLF

	if !Empty(cFiliais) .And. !lTodasFil
		cQry += " AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  			 																	+ CRLF
	endif

	cQry += " GROUP BY SD2.D2_FILIAL "	  			   											  	   												+ CRLF
	cQry += " ORDER BY LITROS "	
	
	If "ORACLE" $ cSGBD //Oracle 
		cQry += " ) TMP WHERE ROWNUM <= 1"
	endif	 						 				   																		+ CRLF

	cQry := ChangeQuery(cQry)
	MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

	if  QRY->(!Eof())
		aadd(aFilMenor,{QRY->FILIAL,QRY->LITROS})
	else
		aadd(aFilMenor,{"",0})
	endif

//////////////////////////  COMPORTAMENTO DO CONSUMO  /////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := " SELECT " 																	   						 		+ CRLF
	cQry += " MES_ANTERIOR.LITROS AS LITROS_ANTERIOR, " 														 		+ CRLF
	cQry += " MES_ATUAL.LITROS AS LITROS_ATUAL " 																 		+ CRLF
	cQry += " FROM " 																	   						  		+ CRLF
	cQry += " ( " 																	   					   		  		+ CRLF
	cQry += " 	SELECT " 																	   					  		+ CRLF
	cQry += " 	SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) LITROS, "											  		+ CRLF
	cQry += " 	SUM(SD2.D2_TOTAL) REAIS " 																		  		+ CRLF
	cQry += " 	FROM " 																	   						  		+ CRLF
	cQry += 	RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												   	 			   		+ CRLF

	cQry += " 	INNER JOIN " 																	   				   		+ CRLF
	cQry += 	RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												   	  			  		+ CRLF
	cQry += " 	ON ( " 																	   					   	 		+ CRLF
	cQry += " 		SD2.D2_COD = SB1.B1_COD " 																	  	 	+ CRLF
	cQry += " 		AND SB1.D_E_L_E_T_ <> '*' " 																  		+ CRLF
	cQry += " 		AND ( SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_COMBUS"),"/")											+ CRLF //Combustíveis
	cQry += " 			OR SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_XGRARLA",,""),"/") + " )"									+ CRLF //Arla
	cQry += " 		) " 																	   					  		+ CRLF

	cQry += " 	INNER JOIN " 																							+ CRLF
	cQry += + 	RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""								 										+ CRLF
	cQry += " 	ON ( "									   				  												+ CRLF
	cQry += "  		SD2.D2_DOC = SF2.F2_DOC "								 											+ CRLF
	cQry += " 		AND SD2.D2_SERIE = SF2.F2_SERIE "					 												+ CRLF
	cQry += " 		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "					  											+ CRLF
	cQry += "  		AND SD2.D2_LOJA = SF2.F2_LOJA "   						 											+ CRLF
	cQry += " 		AND SD2.D2_FILIAL = SF2.F2_FILIAL "																	+ CRLF
	cQry += " 		AND SF2.D_E_L_E_T_ <> '*' "								  										  	+ CRLF
	cQry += " 		AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
	cQry += "		AND SF2.F2_TIPO = 'N'"																				+ CRLF
	cQry += " 	) "						  																				+ CRLF

	cQry += " 	INNER JOIN " 												  											+ CRLF
	cQry += + 	RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""							  											+ CRLF
	cQry += " 	ON ( "									  					  											+ CRLF
	cQry += " 		SF2.F2_CLIENTE = SA1.A1_COD "							 											+ CRLF
	cQry += " 		AND SF2.F2_LOJA = SA1.A1_LOJA "	 						  										 	+ CRLF
	cQry += " 		AND SA1.D_E_L_E_T_ <> '*' "																			+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += "  		AND SA1.A1_GRPVEN = '" + cGrupo + "' "				  											+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 		AND SA1.A1_COD = '" + cCliente + "' "				   											+ CRLF
		cQry += " 		AND SA1.A1_LOJA = '" + cLoja + "' "						  										+ CRLF
	endif

	cQry += "  		) "																					 				+ CRLF

	if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

		cQry += " INNER JOIN " 																		+ CRLF
		cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
		cQry += " ON ( "									  										+ CRLF
		cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
		cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
		cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
		cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
		cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF

		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "					+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "					+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "										+ CRLF
		endif

		cQry += " 	) "	 																			+ CRLF

	endif

	cQry += " 	WHERE " 																	   					  		+ CRLF
	cQry += " 	SD2.D_E_L_E_T_ <> '*' " 																	   	  		+ CRLF

	if !Empty(cFiliais)
		cQry += " 	AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  		  										+ CRLF
	endif

	cQry += " 	AND SUBSTRING(SD2.D2_EMISSAO,1,6) = '" + AnoMes(MonthSub(dDataBase, 1)) + "'  "							+ CRLF
	cQry += " 	AND DAY( CAST( SD2.D2_EMISSAO AS DATETIME ) ) <= DAY( CAST( '" + DTOS(dDataBase) + "' AS DATETIME) ) " 	+ CRLF
	cQry += " ) AS MES_ANTERIOR , " 																	   				+ CRLF
	cQry += " ( " 																	   							   		+ CRLF
	cQry += " 	SELECT " 																	   					   		+ CRLF
	cQry += " 	SUM(SD2.D2_QUANT - ISNULL(SD2.D2_QTDEDEV,0)) LITROS, "											  	 	+ CRLF
	cQry += " 	SUM(SD2.D2_TOTAL) REAIS " 																	   	   		+ CRLF
	cQry += " 	FROM " 																	   						  		+ CRLF
	cQry += 	RetSqlName("SD2") + " SD2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												   	  			 		+ CRLF

	cQry += " 	INNER JOIN " 																	   				 		+ CRLF
	cQry += 	RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												   	  			  		+ CRLF
	cQry += " 	ON ( " 																	   						 		+ CRLF
	cQry += " 		SD2.D2_COD = SB1.B1_COD " 																	  	 	+ CRLF
	cQry += " 		AND SB1.D_E_L_E_T_ <> '*' " 																   		+ CRLF
	cQry += " 		AND ( SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_COMBUS"),"/")											+ CRLF //Combustíveis
	cQry += " 			OR SB1.B1_GRUPO IN "+FormatIN(SuperGetMV("MV_XGRARLA",,""),"/") + " )"									+ CRLF //Arla
	cQry += " 		) " 																	   					  		+ CRLF

	cQry += " 	INNER JOIN " 											  												+ CRLF
	cQry += + 	RetSqlName("SF2") + " SF2 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""						   												+ CRLF
	cQry += " 	ON ( "									   				  												+ CRLF
	cQry += "  		SD2.D2_DOC = SF2.F2_DOC "								 											+ CRLF
	cQry += " 		AND SD2.D2_SERIE = SF2.F2_SERIE "																	+ CRLF
	cQry += " 		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "						  										+ CRLF
	cQry += "  		AND SD2.D2_LOJA = SF2.F2_LOJA "   																	+ CRLF
	cQry += " 		AND SD2.D2_FILIAL = SF2.F2_FILIAL "							  										+ CRLF
	cQry += " 		AND SF2.D_E_L_E_T_ <> '*' "								   										  	+ CRLF
	cQry += " 		AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR(SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"	+ CRLF
	cQry += "		AND SF2.F2_TIPO = 'N'"																				+ CRLF
	cQry += " 	) "							  																			+ CRLF

	cQry += " 	INNER JOIN " 																							+ CRLF
	cQry += + 	RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""							  											+ CRLF
	cQry += " 	ON ( "									  																+ CRLF
	cQry += " 		SF2.F2_CLIENTE = SA1.A1_COD "								 										+ CRLF
	cQry += " 		AND SF2.F2_LOJA = SA1.A1_LOJA "	 						 										 	+ CRLF
	cQry += " 		AND SA1.D_E_L_E_T_ <> '*' "								 											+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += "  		AND SA1.A1_GRPVEN = '" + cGrupo + "' "															+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " 		AND SA1.A1_COD = '" + cCliente + "' "				  											+ CRLF
		cQry += " 		AND SA1.A1_LOJA = '" + cLoja + "' "																+ CRLF
	endif

	cQry += " 		) "																  									+ CRLF

	if cPerspectiva == "MOTORISTA" .or. cPerspectiva == "PLACA"

		cQry += " INNER JOIN " 																		+ CRLF
		cQry += + RetSqlName("SL1") + " SL1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
		cQry += " ON ( "									  										+ CRLF
		cQry += " 	SL1.L1_DOC = SF2.F2_DOC "									   					+ CRLF
		cQry += " 	AND SL1.L1_SERIE = SF2.F2_SERIE "							 					+ CRLF
		cQry += " 	AND SL1.L1_PDV = SF2.F2_PDV "								  					+ CRLF
		cQry += " 	AND SL1.L1_FILIAL = SF2.F2_FILIAL "							   					+ CRLF
		cQry += " 	AND SL1.D_E_L_E_T_ <> '*' "														+ CRLF

		if cPerspectiva == "MOTORISTA"
			if SL1->(FieldPos("L1_CGCMOTO")) > 0
				cQry += " 	AND SL1.L1_CGCMOTO = '" + cMotorista + "' "					+ CRLF
			else
				cQry += " 	AND SL1.L1_CGCCLI = '" + cMotorista + "' "					+ CRLF
			endif
		endif

		if cPerspectiva == "PLACA"
			cQry += " 	AND SL1.L1_PLACA = '" + cPlaca + "' "										+ CRLF
		endif

		cQry += " 	) "	 																			+ CRLF

	endif

	cQry += " 	WHERE " 																	   					  		+ CRLF
	cQry += " 	SD2.D_E_L_E_T_ <> '*' " 																	   	  		+ CRLF

	if !Empty(cFiliais) .And. !lTodasFil
		cQry += " 	AND SD2.D2_FILIAL IN " + FormatIn(cFiliais,",") 	  		  										+ CRLF
	endif

	cQry += " 	AND SUBSTRING(SD2.D2_EMISSAO,1,6) = '" + AnoMes(dDataBase) + "' " 								  		+ CRLF
	cQry += " ) AS MES_ATUAL " 																	   				 		+ CRLF

	cQry := ChangeQuery(cQry)
	MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

	if  QRY->(!Eof())

		if QRY->LITROS_ANTERIOR > QRY->LITROS_ATUAL
			cComportamento := "Volume em queda!"
		elseif QRY->LITROS_ANTERIOR == QRY->LITROS_ATUAL
			cComportamento := "Volume estável!"
		else
			cComportamento := "Volume em crescimento!"
		endif

		aadd(aComportamento,{cComportamento,QRY->LITROS_ANTERIOR,QRY->LITROS_ATUAL})

	else
		aadd(aComportamento,{"",0,0})
	endif

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

//////////////////////////  QUANTIDADE FROTA  /////////////////////////

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

	cQry := " SELECT "
	cQry += " COUNT(*) AS QUANTIDADE "			   											  	  	+ CRLF
	cQry += " FROM " 																		  	  	+ CRLF
	cQry += RetSqlName("DA3") + " DA3 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												   	  	+ CRLF
	cQry += " WHERE "									  										  	+ CRLF
	cQry += " DA3.D_E_L_E_T_ <> '*' " 							  									+ CRLF

	if cPerspectiva == "GRUPO"
		cQry += " AND DA3.DA3_XGRPCL = '" + cGrupo + "' "				   							+ CRLF
	endif

	if cPerspectiva == "CLIENTE"
		cQry += " AND DA3.DA3_XCODCL = '" + cCliente + "' "					   						+ CRLF
		cQry += " AND DA3.DA3_XLOJCL = '" + cLoja + "' "					 							+ CRLF
	endif

	cQry := ChangeQuery(cQry)
	MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

	if  QRY->(!Eof())
		nQtdFrota := QRY->QUANTIDADE
	endif

	If Select("QRY") > 0
		QRY->(DbCloseArea())
	EndIf

//////////////////////////  DATA DE INCLUSAO  /////////////////////////

	if cPerspectiva == "CLIENTE"

		if SA1->(FieldPos("A1_DTCAD"))>0
			SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD + A1_LOJA
			if SA1->(DbSeek(xFilial("SA1") + cCliente + cLoja))
				dDataInclusao := SA1->A1_DTCAD
			endif
		endif

	endif

////////////////////////  DIAS PARA ANIVERSARIO  /////////////////////

	if cPerspectiva == "MOTORISTA"

		DA4->(DbSetOrder(3))
		if DA4->(DbSeek(xFilial("DA4") + cMotorista))

			if !Empty(DA4->DA4_DATNAS)

				if Month(DA4->DA4_DATNAS) > Month(dDataBase) // se o mes do nascimento for maior que o mes atual
					dProxNiver := YearSum(DA4->DA4_DATNAS , DateDiffYear(dDataBase,DA4->DA4_DATNAS) + 1)
				else
					dProxNiver := YearSum(DA4->DA4_DATNAS , DateDiffYear(dDataBase,DA4->DA4_DATNAS))
				endif

				if dProxNiver > dDataBase
					nDiasNiver := DateDiffDay(dProxNiver,dDataBase)
				else
					nDiasNiver := DateDiffDay(dDataBase,dProxNiver)
				endif

				aAniversario := {iif(nDiasNiver == 0,.T.,.F.),nDiasNiver}

			endif

		endif

	endif

////////////////////  Montagem do array de retorno  //////////////////

	aadd(aRet, aUltVendas  		) // X últimas vendas
	aadd(aRet, aUltMeses   		) // últimas vendas do cliente nos últmimos X meses
	aadd(aRet, aGrafico	   		) // Dados do grafico
	aadd(aRet, aTotalVendas		) // Total de vendas em litros
	aadd(aRet, aMelhorMes		) // Mês / Ano de maior consumo em litros
	aadd(aRet, aFilMenor   		) // Filial com menor consumo nos últimos X dias
	aadd(aRet, aComportamento	) // Comportamento de consumo
	aadd(aRet, nQtdFrota		) // quantidade da frota
	aadd(aRet, dDataInclusao	) // data de inclusão da entidade
	aadd(aRet, aAniversario  	) // dados de aniversário do motorista

Return(aRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³BuscaHistCreditoºAutor³Wellington Gonçalvesº Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Consulta SQL do histórico de crédito						  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function BuscaHistCredito(cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais)

	Local cQry 		   	:= ""
	Local aRet			:= {}
	Local aCheques		:= {}
	Local aTitulos		:= {}
	Local aCredito		:= {}
	Local aBloqueio		:= {}
	Local cOperacao		:= ""
	Local cFiliais		:= ""
	Local nX := 0

// converto o array de filiais selecionadas em string para utilizar na consulta SQL
	For nX := 1 To Len(aFiliais)

		if aFiliais[nX,1] == "OK"
			cFiliais += iif(Empty(cFiliais),"",",") + aFiliais[nX,2]
		endif

	Next nX

// apenas a perspectiva de cliente e grupo visualiza o histórico de crédito
	if cPerspectiva == "CLIENTE" .OR. cPerspectiva == "GRUPO"

		///////////////////////////////////  CRÉDITO  ///////////////////////////////////////
		// Alteração da Query em virtude de as procedures ainda não estarem em execução - Maiki - 27/01/2017

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		EndIf

		cQry := " SELECT " 													   																+ CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " 0	AS VLR_LIM_CHQ,"		 			   								 				   			+ CRLF // quantidade - limite disponivel de cheques
			cQry += " 0 AS VLR_CHQ_TOT_UTIL,"		 																	+ CRLF
			cQry += " 0 AS QTD_LIM_CHQ_DISPONIVEL,"			 			   												+ CRLF // quantidade - limite disponivel de cheques
			cQry += " 0 AS VLR_LIM_CHQ_DISPONIVEL,"				 	 	 												+ CRLF // valor - limite disponivel de cheques
		else
			cQry += " 0 AS VLR_LIM_CHQ,"																									+ CRLF

			cQry += " 0 AS VLR_CHQ_TOT_UTIL,"	 																							+ CRLF
			cQry += " 0 AS QTD_LIM_CHQ_DISPONIVEL,"			 			   																	+ CRLF // quantidade - limite disponivel de cheques

			cQry += " 0 AS VLR_LIM_CHQ_DISPONIVEL,"																							+ CRLF
		Endif

		cQry += " (SELECT COUNT(SE1.E1_NUM) FROM"																						+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SE5")+" SE5 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*'"																							+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*'"																							+ CRLF
		cQry += " AND SE5.D_E_L_E_T_ 	<> '*'"																							+ CRLF
		if !Empty(cFiliais)
			cQry += " 	AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " 	AND SE5.E5_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA 	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SE5.E5_FILIAL 	= SE1.E1_FILIAL"					  															+ CRLF
		cQry += " AND SE5.E5_NATUREZ	= SE1.E1_NATUREZ"																				+ CRLF
		cQry += " AND SE5.E5_PREFIXO	= SE1.E1_PREFIXO"																				+ CRLF
		cQry += " AND SE5.E5_NUMERO		= SE1.E1_NUM"																					+ CRLF
		cQry += " AND SE5.E5_PARCELA	= SE1.E1_PARCELA"																				+ CRLF
		cQry += " AND SE5.E5_TIPO		= SE1.E1_TIPO"																					+ CRLF
		cQry += " AND SE5.E5_CLIFOR		= SE1.E1_CLIENTE"																				+ CRLF
		cQry += " AND SE5.E5_LOJA		= SE1.E1_LOJA"																					+ CRLF
		//cQry += " AND SE1.E1_SALDO 		= 0"																							+ CRLF
		cQry += " AND SE1.E1_TIPO 		IN ('CH','CHD')"																				+ CRLF
		cQry += " AND SE1.E1_ORIGEM   	<> 'FINA087A'"																					+ CRLF
		cQry += " AND SE5.E5_RECPAG		= 'R' "																							+ CRLF
		cQry += " AND SE5.E5_MOTBX 		NOT IN ('FAT','LIQ')"																	   		+ CRLF
		cQry += " AND SE5.E5_SITUACA  	<> 'C'"																							+ CRLF
		cQry += " AND SE5.E5_BANCO    	<> ''"																							+ CRLF

		cQry += " AND NOT EXISTS ("																										+CRLF
		cQry += " SELECT A.E5_NUMERO"																									+CRLF
		cQry += " FROM " + RetSqlName('SE5') + " A "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""																			+CRLF
		cQry += " WHERE A.E5_FILIAL		= SE5.E5_FILIAL"																				+CRLF
		cQry += " AND A.E5_NATUREZ		= SE5.E5_NATUREZ"																				+CRLF
		cQry += " AND A.E5_PREFIXO		= SE5.E5_PREFIXO"																				+CRLF
		cQry += " AND A.E5_NUMERO		= SE5.E5_NUMERO"																		   		+CRLF
		cQry += " AND A.E5_PARCELA		= SE5.E5_PARCELA"																		   		+CRLF
		cQry += " AND A.E5_TIPO			= SE5.E5_TIPO"																					+CRLF
		cQry += " AND A.E5_CLIFOR		= SE5.E5_CLIFOR"																				+CRLF
		cQry += " AND A.E5_LOJA			= SE5.E5_LOJA"																					+CRLF
		cQry += " AND A.E5_SEQ			= SE5.E5_SEQ"																	  				+CRLF
		cQry += " AND A.E5_TIPODOC		= 'ES'"																				 			+CRLF
		cQry += " AND A.E5_RECPAG		<> 'R'"																				 			+CRLF
		cQry += " AND A.D_E_L_E_T_<>'*') "																								+CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD 	= '" + cCliente + "'"			  															+ CRLF
			cQry += " AND SA1AUX.A1_LOJA 	= '" + cLoja + "'"													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN 	= '" + cGrupo + "'"																			+ CRLF
		endif
		cQry += " )AS QTD_CHQ_COMPENSADO,"																								+ CRLF

		cQry += " (SELECT SUM(SE1.E1_VALOR) FROM"																						+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SE5")+" SE5 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		cQry += " AND SE5.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " AND SE5.E5_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA 	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SE5.E5_FILIAL 	= SE1.E1_FILIAL"					  															+ CRLF
		cQry += " AND SE5.E5_NATUREZ	= SE1.E1_NATUREZ"																	 			+ CRLF
		cQry += " AND SE5.E5_PREFIXO	= SE1.E1_PREFIXO"																   				+ CRLF
		cQry += " AND SE5.E5_NUMERO		= SE1.E1_NUM"																	  				+ CRLF
		cQry += " AND SE5.E5_PARCELA	= SE1.E1_PARCELA"																   				+ CRLF
		cQry += " AND SE5.E5_TIPO		= SE1.E1_TIPO"																					+ CRLF
		cQry += " AND SE5.E5_CLIFOR		= SE1.E1_CLIENTE"																				+ CRLF
		cQry += " AND SE5.E5_LOJA		= SE1.E1_LOJA"																		 			+ CRLF
		//cQry += " AND SE1.E1_SALDO 		= 0"																				  			+ CRLF
		cQry += " AND SE1.E1_ORIGEM   	<> 'FINA087A'"																					+ CRLF
		cQry += " AND SE1.E1_TIPO 		IN ('CH','CHD')"																	  			+ CRLF
		cQry += " AND SE5.E5_RECPAG		= 'R'"																							+ CRLF
		cQry += " AND SE5.E5_MOTBX 		NOT IN ('FAT','LIQ')"																	   		+ CRLF
		cQry += " AND SE5.E5_SITUACA  	<> 'C'"																							+ CRLF
		cQry += " AND SE5.E5_BANCO    	<> ''"																							+ CRLF

		cQry += " AND NOT EXISTS ( "																									+CRLF
		cQry += " SELECT A.E5_NUMERO "																									+CRLF
		cQry += " FROM " + RetSqlName('SE5') + " A "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""																			+CRLF
		cQry += " WHERE A.E5_FILIAL		= SE5.E5_FILIAL"																				+CRLF
		cQry += " AND A.E5_NATUREZ		= SE5.E5_NATUREZ"																				+CRLF
		cQry += " AND A.E5_PREFIXO		= SE5.E5_PREFIXO"																				+CRLF
		cQry += " AND A.E5_NUMERO		= SE5.E5_NUMERO"																		   		+CRLF
		cQry += " AND A.E5_PARCELA		= SE5.E5_PARCELA"																		   		+CRLF
		cQry += " AND A.E5_TIPO			= SE5.E5_TIPO"																					+CRLF
		cQry += " AND A.E5_CLIFOR		= SE5.E5_CLIFOR"																				+CRLF
		cQry += " AND A.E5_LOJA			= SE5.E5_LOJA"																					+CRLF
		cQry += " AND A.E5_SEQ			= SE5.E5_SEQ"																	  				+CRLF
		cQry += " AND A.E5_TIPODOC		= 'ES'"																				 			+CRLF
		cQry += " AND A.E5_RECPAG		<> 'R'"																				 			+CRLF
		cQry += " AND A.D_E_L_E_T_<>'*') "																								+CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD 	= '" + cCliente + "'"		  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA 	= '" + cLoja + "'"													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN 	= '" + cGrupo + "'"																			+ CRLF
		endif
		cQry += " )AS VLR_CHQ_COMPENSADO,"																								+ CRLF

		cQry += " (SELECT COUNT(SE1.E1_NUM) FROM"		   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*'"																							+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*'"																							+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA 	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD 	= '" + cCliente + "'"		  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA 	= '" + cLoja + "'"													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "'"																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 		> 0"																							+ CRLF
		cQry += " AND SE1.E1_TIPO IN 	('CH','CHD')"																					+ CRLF
		cQry += " )AS QTD_CHQ_PENDENTE,"																								+ CRLF

		cQry += " (SELECT SUM(SE1.E1_SALDO) FROM"		   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*'"																							+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*'"																							+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA 	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "'"			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "'"													  							+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "'"																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 		> 0"																							+ CRLF
		cQry += " AND SE1.E1_TIPO IN 	('CH','CHD')"																					+ CRLF
		cQry += " )AS VLR_CHQ_PENDENTE,"																								+ CRLF

		cQry += " (SELECT COUNT(SE1.E1_NUM) FROM"		   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SEF")+" SEF "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SEF.D_E_L_E_T_ <> '*' "																					   		+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " AND SEF.EF_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SE1.E1_FILIAL 	= SEF.EF_FILIAL"		  		  																+ CRLF
		cQry += " AND SE1.E1_PREFIXO 	= SEF.EF_PREFIXO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_NUM 		= SEF.EF_TITULO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_PARCELA 	= SEF.EF_PARCELA"		  		  																+ CRLF
		cQry += " AND SE1.E1_TIPO 		= SEF.EF_TIPO"		  		  													   				+ CRLF
		cQry += " AND SEF.EF_CLIENTE	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SEF.EF_LOJACLI	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 		= 0 "																							+ CRLF
		cQry += " AND (SEF.EF_DTALIN1 <> ' ' OR SEF.EF_DTALIN2 <> ' ')"																	+ CRLF
		cQry += " AND ((SEF.EF_DTALIN1 > SE1.E1_BAIXA ) OR (SEF.EF_DTALIN2 > SE1.E1_BAIXA))"											+ CRLF
		cQry += " ) AS QTD_CHQ_DEVOLVIDO_PAGO, "																						+ CRLF

		cQry += " (SELECT SUM(SE1.E1_VALOR) FROM	"	   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SEF")+" SEF "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SEF.D_E_L_E_T_ <> '*' "																					   		+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " AND SEF.EF_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SE1.E1_FILIAL 	= SEF.EF_FILIAL"		  		  																+ CRLF
		cQry += " AND SE1.E1_PREFIXO 	= SEF.EF_PREFIXO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_NUM 		= SEF.EF_TITULO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_PARCELA 	= SEF.EF_PARCELA"		  		  																+ CRLF
		cQry += " AND SE1.E1_TIPO 		= SEF.EF_TIPO"		  		  													   				+ CRLF
		cQry += " AND SEF.EF_CLIENTE	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SEF.EF_LOJACLI	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		//cQry += " AND SE1.E1_SALDO 		= 0 "																						+ CRLF
		cQry += " AND (SEF.EF_DTALIN1 <> ' ' OR SEF.EF_DTALIN2 <> ' ')"																	+ CRLF
		cQry += " AND ((SEF.EF_DTALIN1 > SE1.E1_BAIXA ) OR (SEF.EF_DTALIN2 > SE1.E1_BAIXA))"											+ CRLF
		cQry += " ) AS VLR_CHQ_DEVOLVIDO_PAGO, "																						+ CRLF

		cQry += " (SELECT SUM(SE1.E1_VALOR) FROM	"	   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SEF")+" SEF "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SEF.D_E_L_E_T_ <> '*' "																					   		+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " AND SEF.EF_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SE1.E1_FILIAL 	= SEF.EF_FILIAL"		  		  																+ CRLF
		cQry += " AND SE1.E1_PREFIXO 	= SEF.EF_PREFIXO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_NUM 		= SEF.EF_TITULO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_PARCELA 	= SEF.EF_PARCELA"		  		  																+ CRLF
		cQry += " AND SE1.E1_TIPO 		= SEF.EF_TIPO"		  		  													   				+ CRLF
		cQry += " AND SEF.EF_CLIENTE	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SEF.EF_LOJACLI	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 		> 0 "																							+ CRLF
		cQry += " AND (SEF.EF_DTALIN1 <> ' ' OR SEF.EF_DTALIN2 <> ' ')"																	+ CRLF
		cQry += " AND ((SEF.EF_DTALIN1 > SE1.E1_BAIXA ) OR (SEF.EF_DTALIN2 > SE1.E1_BAIXA))"											+ CRLF
		cQry += " ) AS VLR_CHQ_DE_ABERTO, "																					   			+ CRLF

		cQry += " (SELECT COUNT(SE1.E1_NUM) FROM	"	   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SEF")+" SEF "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SEF.D_E_L_E_T_ <> '*' "																					   		+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " AND SEF.EF_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SE1.E1_FILIAL 	= SEF.EF_FILIAL"		  		  																+ CRLF
		cQry += " AND SE1.E1_PREFIXO 	= SEF.EF_PREFIXO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_NUM 		= SEF.EF_TITULO"		  		  													   			+ CRLF
		cQry += " AND SE1.E1_PARCELA 	= SEF.EF_PARCELA"		  		  																+ CRLF
		cQry += " AND SE1.E1_TIPO 		= SEF.EF_TIPO"		  		  													   				+ CRLF
		cQry += " AND SEF.EF_CLIENTE	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SEF.EF_LOJACLI	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_COD 	= (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"					+ CRLF
		cQry += " AND SA1AUX.A1_LOJA	= (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 		> 0 "																							+ CRLF
		cQry += " AND (SEF.EF_DTALIN1 <> ' ' OR SEF.EF_DTALIN2 <> ' ')"																	+ CRLF
		cQry += " AND ((SEF.EF_DTALIN1 > SE1.E1_BAIXA ) OR (SEF.EF_DTALIN2 > SE1.E1_BAIXA))"											+ CRLF
		cQry += " ) AS QTD_CHQ_DEVOLVIDO_ABERTO, "																						+ CRLF

		cQry += " (SELECT COUNT(SE1.E1_NUM) FROM	"	   																				+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 			> 0 "																						+ CRLF
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ')  "									+ CRLF
		cQry += " ) AS QTD_TIT_AB, "																									+ CRLF

		cQry += " (SELECT SUM(SE1.E1_SALDO) FROM	"																					+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")	  		  														+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_SALDO 			> 0 "																						+ CRLF
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ')  "									+ CRLF
		cQry += " ) AS VLR_TIT_AB, "																									+ CRLF
		// cQry += " SUM(SA1.A1_SALDUP) 	AS VLR_TITULOS_ABERTO, "						 											+ CRLF // valor de títulos em aberto

		cQry += " (SELECT COUNT(SE5.E5_NUMERO) FROM	"																					+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SE5")+" SE5 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		cQry += " AND SE5.D_E_L_E_T_ <> '*' "																							+ CRLF
		if !Empty(cFiliais)
			cQry += " 	AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " 	AND SE5.E5_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SE5.E5_FILIAL		= SE1.E1_FILIAL "																				+ CRLF
		cQry += " AND SE5.E5_NATUREZ	= SE1.E1_NATUREZ "																				+ CRLF
		cQry += " AND SE5.E5_PREFIXO	= SE1.E1_PREFIXO "																		   		+ CRLF
		cQry += " AND SE5.E5_NUMERO		= SE1.E1_NUM "																					+ CRLF
		cQry += " AND SE5.E5_PARCELA	= SE1.E1_PARCELA "																	 			+ CRLF
		cQry += " AND SE5.E5_TIPO		= SE1.E1_TIPO "																					+ CRLF
		cQry += " AND SE5.E5_CLIFOR		= SE1.E1_CLIENTE "																				+ CRLF
		cQry += " AND SE5.E5_LOJA		= SE1.E1_LOJA "																					+ CRLF
		cQry += " AND SE5.E5_RECPAG		= 'R' "																				 			+ CRLF
		cQry += " AND SE5.E5_SITUACA	<> 'C' "																			  			+ CRLF
		cQry += " AND SE5.E5_MOTBX 		<> 'FAT' "																			  			+ CRLF
		cQry += " AND SE5.E5_MOTBX 		<> 'LIQ' "																			   			+ CRLF
		cQry += " AND SE5.E5_BANCO 		<> '' "																							+ CRLF

		cQry += " AND NOT EXISTS ( "																									+CRLF
		cQry += " SELECT A.E5_NUMERO "																									+CRLF
		cQry += " FROM " + RetSqlName('SE5') + " A "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""																			+CRLF
		cQry += " WHERE A.E5_FILIAL		= SE5.E5_FILIAL"																				+CRLF
		cQry += " AND A.E5_NATUREZ		= SE5.E5_NATUREZ"																				+CRLF
		cQry += " AND A.E5_PREFIXO		= SE5.E5_PREFIXO"																				+CRLF
		cQry += " AND A.E5_NUMERO		= SE5.E5_NUMERO"																		   		+CRLF
		cQry += " AND A.E5_PARCELA		= SE5.E5_PARCELA"																		   		+CRLF
		cQry += " AND A.E5_TIPO			= SE5.E5_TIPO"																					+CRLF
		cQry += " AND A.E5_CLIFOR		= SE5.E5_CLIFOR"																				+CRLF
		cQry += " AND A.E5_LOJA			= SE5.E5_LOJA"																					+CRLF
		cQry += " AND A.E5_SEQ			= SE5.E5_SEQ"																	  				+CRLF
		cQry += " AND A.E5_TIPODOC		= 'ES'"																				 			+CRLF
		cQry += " AND A.E5_RECPAG		<> 'R'"																				 			+CRLF
		cQry += " AND A.D_E_L_E_T_<>'*') "																								+CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE 	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ') "									+ CRLF
		cQry += " ) AS QTD_TIT_PAG, "																									+ CRLF

		cQry += " (SELECT SUM(SE5.E5_VALOR) FROM "																						+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SE5")+" SE5 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""		+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		cQry += " AND SE5.D_E_L_E_T_ <> '*' "																							+ CRLF
		if !Empty(cFiliais)
			cQry += " 	AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
			cQry += " 	AND SE5.E5_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		cQry += " AND SE5.E5_FILIAL		= SE1.E1_FILIAL "																				+ CRLF
		cQry += " AND SE5.E5_NATUREZ	= SE1.E1_NATUREZ "																	 			+ CRLF
		cQry += " AND SE5.E5_PREFIXO	= SE1.E1_PREFIXO "																				+ CRLF
		cQry += " AND SE5.E5_NUMERO		= SE1.E1_NUM "																	  				+ CRLF
		cQry += " AND SE5.E5_PARCELA	= SE1.E1_PARCELA "																   				+ CRLF
		cQry += " AND SE5.E5_TIPO		= SE1.E1_TIPO "																	   				+ CRLF
		cQry += " AND SE5.E5_CLIFOR		= SE1.E1_CLIENTE "																				+ CRLF
		cQry += " AND SE5.E5_LOJA		= SE1.E1_LOJA "																		 			+ CRLF
		cQry += " AND SE5.E5_RECPAG		= 'R' "																				  			+ CRLF
		cQry += " AND SE5.E5_SITUACA	<> 'C' "																			  			+ CRLF
		cQry += " AND SE5.E5_MOTBX 		<> 'FAT' "																			  			+ CRLF
		cQry += " AND SE5.E5_MOTBX 		<> 'LIQ' "																			  			+ CRLF
		cQry += " AND SE5.E5_BANCO 		<> '' "																							+ CRLF

		cQry += " AND NOT EXISTS ( "																									+CRLF
		cQry += " SELECT A.E5_NUMERO "																									+CRLF
		cQry += " FROM " + RetSqlName('SE5') + " A "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""																			+CRLF
		cQry += " WHERE A.E5_FILIAL		= SE5.E5_FILIAL"																				+CRLF
		cQry += " AND A.E5_NATUREZ		= SE5.E5_NATUREZ"																				+CRLF
		cQry += " AND A.E5_PREFIXO		= SE5.E5_PREFIXO"																				+CRLF
		cQry += " AND A.E5_NUMERO		= SE5.E5_NUMERO"																		   		+CRLF
		cQry += " AND A.E5_PARCELA		= SE5.E5_PARCELA"																		   		+CRLF
		cQry += " AND A.E5_TIPO			= SE5.E5_TIPO"																					+CRLF
		cQry += " AND A.E5_CLIFOR		= SE5.E5_CLIFOR"																				+CRLF
		cQry += " AND A.E5_LOJA			= SE5.E5_LOJA"																					+CRLF
		cQry += " AND A.E5_SEQ			= SE5.E5_SEQ"																	  				+CRLF
		cQry += " AND A.E5_TIPODOC		= 'ES'"																				 			+CRLF
		cQry += " AND A.E5_RECPAG		<> 'R'"																				 			+CRLF
		cQry += " AND A.D_E_L_E_T_<>'*') "																								+CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ') "									+ CRLF
		cQry += " ) AS VLR_TIT_PAG, "																									+ CRLF

		cQry += " (SELECT COUNT(SE1.E1_NUM) FROM	"																					+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")	  		  														+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_VENCREA		< "+DToS(dDataBase)+""																		+ CRLF
		cQry += " AND SE1.E1_SALDO 			> 0 "																						+ CRLF
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ') "									+ CRLF
		cQry += " ) AS QTD_TIT_VENC, "																									+ CRLF

		cQry += " (SELECT SUM(SE1.E1_VALOR)	FROM"																						+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " 	AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_VENCREA		< "+DToS(dDataBase)+""																		+ CRLF
		cQry += " AND SE1.E1_SALDO 			> 0 "																						+ CRLF
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																		   		+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ')  "									+ CRLF
		cQry += " ) AS VLR_TIT_VENC, "																									+ CRLF
		//cQry += " SUM(SA1.A1_ATR) 		AS VLR_TIT_VENCIDOS, "					 											   		+ CRLF // valor - títulos vencidos

		if "ORACLE"$cSGBD
			cQry += " (SELECT AVG(ABS( TO_DATE(SE1.E1_VENCREA, 'YYYYMMDD') - TO_DATE(SE1.E1_BAIXA, 'YYYYMMDD') )) FROM "		  																+ CRLF
		else
			cQry += " (SELECT AVG(ABS(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME) , CAST(SE1.E1_BAIXA AS DATETIME) ) ) ) FROM "		  																+ CRLF
		endif
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " 	AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")		  															+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_BAIXA			> SE1.E1_VENCREA"																			+ CRLF
		cQry += " AND SE1.E1_ORIGEM 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE 	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ')  "									+ CRLF
		cQry += " ) AS QTD_DIAS_MEDIA_ATRASO, "																							+ CRLF

		cQry += " (SELECT AVG(SE1.E1_VALOR)	FROM"																						+ CRLF
		cQry += " "+RetSqlName("SE1")+" SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+", "+RetSqlName("SA1")+" SA1AUX "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""											+ CRLF
		cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*' "																						+ CRLF
		cQry += " AND SA1AUX.D_E_L_E_T_ <> '*' "																						+ CRLF
		if !Empty(cFiliais)
			cQry += " AND SE1.E1_FILIAL IN " + FormatIn(cFiliais,",")	  		  														+ CRLF
		endif
		cQry += " AND SA1AUX.A1_FILIAL 	= '" + xFilial("SA1") + "'"		  		  														+ CRLF
		cQry += " AND SA1AUX.A1_COD = (CASE WHEN SE1.E1_XCODEMI = '' THEN SE1.E1_CLIENTE ELSE SE1.E1_XCODEMI END)"						+ CRLF
		cQry += " AND SA1AUX.A1_LOJA = (CASE WHEN SE1.E1_XLOJEMI = '' THEN SE1.E1_LOJA ELSE SE1.E1_XLOJEMI END)"						+ CRLF
		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1AUX.A1_COD = '" + cCliente + "' "			  																+ CRLF
			cQry += " AND SA1AUX.A1_LOJA = '" + cLoja + "' "													  						+ CRLF
		endif
		if cPerspectiva == "GRUPO"
			cQry += " AND SA1AUX.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif
		cQry += " AND SE1.E1_BAIXA			> SE1.E1_VENCREA"																			+ CRLF
		cQry += " AND SE1.E1_ORIGEM	 		<> 'FINA087A' "																				+ CRLF
		cQry += " AND SE1.E1_TIPO NOT LIKE 	'__-' "																						+ CRLF
		cQry += " AND SE1.E1_TIPO NOT IN 	('RA ','PA ','NCC','NDF','PR ','CH ','CHD','R$ ','CR ')  "									+ CRLF
		cQry += " ) AS VLR_MEDIA_ATRASO, "																						   		+ CRLF

		cQry += " SUM(SA1.A1_XLC) AS LIM_CRED_GLOBAL, "					  												 				+ CRLF // limite de crédito global
		cQry += " 0	AS SLD_CRED_GLOBAL, "																								+ CRLF // saldo de crédito global
		cQry += " 0	AS LIM_RECEBER, "					  												   								+ CRLF // limite de crédito a receber
		cQry += " 0	AS SLD_RECEBER, "					  												   								+ CRLF // saldo de limite a receber
		cQry += " 0	AS LIM_CRED_CHEQUE, "					  												   							+ CRLF // saldo de limite a receber
		cQry += " 0	AS SLD_CRED_CHQEUE, "					  	   											 							+ CRLF // saldo de limite a receber
		cQry += " SUM(SA1.A1_XLIMSQ) AS LIM_CRED_SAQUE, "					  												  			+ CRLF // limite de crédito para saque
		cQry += " 0 AS SLD_CRED_SAQUE "						  												  							+ CRLF // limite de crédito para saque

		cQry += " FROM " 																												+ CRLF
		cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""																					+ CRLF
		cQry += " WHERE "									  							   												+ CRLF
		cQry += " SA1.D_E_L_E_T_ <> '*' " 							  																	+ CRLF
		cQry += " AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "	   																	+ CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1.A1_COD = '" + cCliente + "' "				  																+ CRLF
			cQry += " AND SA1.A1_LOJA = '" + cLoja + "' "														  						+ CRLF
		endif

		if cPerspectiva == "GRUPO"
			cQry += " AND SA1.A1_GRPVEN = '" + cGrupo + "' "																			+ CRLF
		endif

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETA041.txt",cQry)
		MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

		if QRY->(!Eof())

			// dados de cheques
			aadd(aCheques, QRY->QTD_LIM_CHQ_DISPONIVEL	   	   							) // quantidade de cheque disponivel
			aadd(aCheques, QRY->VLR_LIM_CHQ_DISPONIVEL 		   							) // valor de cheque disponível
			aadd(aCheques, QRY->QTD_CHQ_COMPENSADO		   	   							) // quantidade de cheque compensado
			aadd(aCheques, QRY->VLR_CHQ_COMPENSADO	   		   							) // valor de cheque compensado
			aadd(aCheques, QRY->QTD_CHQ_PENDENTE		   	   							) // quantidade de cheque pendente
			aadd(aCheques, QRY->VLR_CHQ_PENDENTE		   	   							) // valor de cheque pendente
			aadd(aCheques, QRY->QTD_CHQ_DEVOLVIDO_PAGO	  								) // quantidade de cheque devolvido pago
			aadd(aCheques, QRY->VLR_CHQ_DEVOLVIDO_PAGO 									) // valor de cheque devolvido pago
			aadd(aCheques, QRY->QTD_CHQ_DEVOLVIDO_ABERTO   	   							) // quantidade de cheque devolvido em aberto
			aadd(aCheques, QRY->VLR_CHQ_DE_ABERTO  										) // valor de cheque devolvido em aberto
			aadd(aCheques, QRY->VLR_LIM_CHQ_DISPONIVEL / QRY->VLR_LIM_CHQ * 100			) // percentual do valor de limite de cheque disponível
			aadd(aCheques, QRY->VLR_CHQ_COMPENSADO / QRY->VLR_CHQ_TOT_UTIL * 100		) // percentual de cheques compensados
			aadd(aCheques, QRY->VLR_CHQ_PENDENTE / QRY->VLR_CHQ_TOT_UTIL * 100			) // percentual de cheques pendentes
			aadd(aCheques, QRY->VLR_CHQ_DEVOLVIDO_PAGO / QRY->VLR_CHQ_TOT_UTIL * 100 	) // percentual de cheques devolvidos pagos
			aadd(aCheques, QRY->VLR_CHQ_DE_ABERTO / QRY->VLR_CHQ_TOT_UTIL * 100			) // percentual de cheques devolvidos pendentes


			// dados de títulos
			aadd(aTitulos, QRY->SLD_RECEBER)
			aadd(aTitulos, QRY->QTD_TIT_AB)
			aadd(aTitulos, QRY->VLR_TIT_AB)
			aadd(aTitulos, QRY->QTD_TIT_PAG)
			aadd(aTitulos, QRY->VLR_TIT_PAG)
			aadd(aTitulos, QRY->QTD_TIT_VENC)
			aadd(aTitulos, QRY->VLR_TIT_VENC)
			aadd(aTitulos, QRY->QTD_DIAS_MEDIA_ATRASO)
			aadd(aTitulos, QRY->VLR_MEDIA_ATRASO)

			// dados de crédito
			aadd(aCredito, QRY->LIM_CRED_GLOBAL)
			if cPerspectiva == "CLIENTE"
				aadd(aCredito, (QRY->LIM_CRED_GLOBAL) - (U_TRETE032(1,{{cCliente,cLoja,''}})[01][01])) //QRY->SLD_CRED_GLOBAL
			elseif cPerspectiva == "GRUPO"
				aadd(aCredito, (QRY->LIM_CRED_GLOBAL) - (U_TRETE032(1,{{'','',cGrupo}})[01][02])) //QRY->SLD_CRED_GLOBAL
			endif
			//aadd(aCredito, QRY->LIM_RECEBER)
			//aadd(aCredito, QRY->SLD_RECEBER)
			//aadd(aCredito, QRY->LIM_CRED_CHEQUE)
			//aadd(aCredito, QRY->SLD_CRED_CHQEUE)
			aadd(aCredito, QRY->LIM_CRED_SAQUE)
			if cPerspectiva == "CLIENTE"
				aadd(aCredito, (QRY->LIM_CRED_SAQUE) - (U_TRETE032(2,{{cCliente,cLoja,''}})[01][01])) //QRY->SLD_CRED_SAQUE
			elseif cPerspectiva == "GRUPO"
				aadd(aCredito, (QRY->LIM_CRED_SAQUE) - (U_TRETE032(2,{{'','',cGrupo}})[01][02])) //QRY->SLD_CRED_SAQUE
			endif

		else

			aCheques 	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			aTitulos	:= {0,0,0,0,0,0,0,0,0}
			aCredito	:= {0,0,0,0}

		endif

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		EndIf

		///////////////////////////////////  RISCO E STATUS  ///////////////////////////////////////

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		EndIf

		cQry := " SELECT " 													   				+ CRLF
		cQry += " SA1.A1_XBLQLC	AS BLOQUEIO_GERAL, "  					 					+ CRLF
		cQry += " '' AS BLOQUEIO_TITULOS, "						 	 	 					+ CRLF
		cQry += " '' AS BLOQUEIO_CHEQUE, "						 							+ CRLF
		cQry += " SA1.A1_XBLQSQ	AS BLOQUEIO_SAQUE, "	 					 				+ CRLF
		cQry += " SA1.A1_XRISCO	AS RISCO "								  			 		+ CRLF
		cQry += " FROM " 																	+ CRLF
		cQry += + RetSqlName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""										+ CRLF

		cQry += " WHERE "									  								+ CRLF
		cQry += " SA1.D_E_L_E_T_ <> '*' " 							  						+ CRLF
		cQry += " AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "	   						+ CRLF

		if cPerspectiva == "CLIENTE"
			cQry += " AND SA1.A1_COD = '" + cCliente + "' "				  					+ CRLF
			cQry += " AND SA1.A1_LOJA = '" + cLoja + "' "									+ CRLF
		endif

		if cPerspectiva == "GRUPO"
			cQry += " AND SA1.A1_GRPVEN = '" + cGrupo + "' "								+ CRLF
		endif

		cQry := ChangeQuery(cQry)
		MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

		if QRY->(!Eof())

			// bloqueios
			aadd(aBloqueio,iif(QRY->BLOQUEIO_GERAL == "1","SIM","NÃO"))
			aadd(aBloqueio,iif(QRY->BLOQUEIO_SAQUE == "1","SIM","NÃO"))
			aadd(aBloqueio,AllTrim(Posicione("SX5",1, xFilial("SX5") + "ZV" + AllTrim(QRY->RISCO),"X5_DESCRI")))

		else
			aBloqueio := {"","",""}
		endif

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		EndIf

	else

		aBloqueio 	:= {"","",""}
		aCheques 	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		aTitulos	:= {0,0,0,0,0,0,0,0,0}
		aCredito	:= {0,0,0,0}

	endif

	aadd(aRet, aCheques 	) // dados de cheques
	aadd(aRet, aTitulos		) // dados de títulos
	aadd(aRet, aCredito		) // dados de crédito
	aadd(aRet, {}	) // histórico de bloqueio
	aadd(aRet, aBloqueio	) // dados de bloqueio

Return(aRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ BuscaPreco º Autor ³ Wellington Gonçalves º Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Consulta SQL dos preços negociados						  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function BuscaPreco(cGrupo,cCliente,cLoja,cMotorista,cPlaca,cPerspectiva,aFiliais)

	Local aArea			:= GetArea()
	Local cQry 		   	:= ""
	Local aRet			:= {}
	Local aPrecos		:= {}
	Local cFiliais		:= ""
	Local cFilBkp 		:= cFilAnt
	Local lNgDesc 		:= SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA
	Local nX 			:= 0
	Local bGetMvFil		:= {|cVar| SuperGetMV(cVar,,.T.) }

// converto o array de filiais selecionadas em string para utilizar na consulta SQL
	For nX := 1 To Len(aFiliais)

		If aFiliais[nX,1] == "OK"
			cFiliais += iif(Empty(cFiliais),"",",") + aFiliais[nX,2]
		EndIf

	Next nX

// apenas a perspectiva de cliente e grupo visualiza o histórico de crédito
	If cPerspectiva == "CLIENTE" .OR. cPerspectiva == "GRUPO"

		///////////////////////////////////  CRÉDITO  ///////////////////////////////////////

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		EndIf

		cQry := " SELECT " 													   						+ CRLF
		cQry += " U25.U25_FILIAL 	AS FILIAL, "		 			   								+ CRLF
		cQry += " U25.U25_FORPAG	AS FORMA, "			 	 				 						+ CRLF
		cQry += " U25.U25_CONDPG	AS CONDPAG, "		 	 				 						+ CRLF
		cQry += " U25.U25_ADMFIN	AS ADMINST, "		 	 				 						+ CRLF
		cQry += " U25.U25_PRODUT	AS CODIGO_PRODUTO, "			 	 	 						+ CRLF
		cQry += " U25.U25_DTINIC	AS DATA_INI_VIGENCIA, "			 	 	 						+ CRLF
		cQry += " U25.U25_HRINIC	AS HORA_INI_VIGENCIA, "			 	 	 						+ CRLF
		cQry += " SB1.B1_DESC  		AS DESCRICAO_PRODUTO, "						 					+ CRLF
		cQry += " U25.U25_PRCVEN	AS VALOR, "							 							+ CRLF
		If U25->(FieldPos("U25_DESPBA"))>0
			cQry += " U25.U25_DESPBA	AS DESCONTO, "							 					+ CRLF
		EndIf
		cQry += " U25.U25_DTFIM		AS DATA_FIM_VIGENCIA, "				 							+ CRLF
		cQry += " U25.U25_HRFIM		AS HORA_FIM_VIGENCIA "				 							+ CRLF
		cQry += " FROM " 																			+ CRLF
		cQry += + RetSqlName("U25") + " U25 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""												+ CRLF
		cQry += " INNER JOIN " 																		+ CRLF
		cQry += + RetSqlName("SB1") + " SB1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""									   			+ CRLF
		cQry += " ON ( "									   										+ CRLF
		cQry += "  	U25.U25_PRODUT = SB1.B1_COD "	   									 			+ CRLF
		cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "									  		   			+ CRLF
		cQry += " 	AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "	   								+ CRLF
		cQry += " 	) "									  											+ CRLF
		cQry += " WHERE "									  							   			+ CRLF
		cQry += " U25.D_E_L_E_T_ <> '*' " 							  								+ CRLF

		If !Empty(cFiliais)
			cQry += " AND U25.U25_FILIAL IN " + FormatIn(cFiliais,",") 	 	 						+ CRLF
		EndIf

		cQry += " AND U25.U25_BLQL <> 'S' "						 	 	 							+ CRLF

		If cPerspectiva == "CLIENTE"
			cQry += " AND U25.U25_CLIENT = '" + cCliente + "' "				  				   		+ CRLF
			cQry += " AND U25.U25_LOJA = '" + cLoja + "' "							   				+ CRLF
		EndIf

		If cPerspectiva == "GRUPO"
			cQry += " AND U25.U25_GRPCLI = '" + cGrupo + "' "				   						+ CRLF
		EndIf

		cQry += " ORDER BY U25.U25_FILIAL, U25.U25_FORPAG "											+ CRLF

		cQry := ChangeQuery(cQry)
		MPSysOpenQuery( cQry, 'QRY' ) // Cria uma nova area com o resultado do query

		If QRY->(!Eof())

			While QRY->(!Eof())

				aPrecos := {}

				cDescFr := AllTrim(Posicione("SX5",1,xFilial("SX5")+"24"+AllTrim(QRY->FORMA),"X5_DESCRI"))
				cDescCd := AllTrim(Posicione("SE4",1,xFilial("SE4")+AllTrim(QRY->CONDPAG),"E4_DESCRI"))
				nPrcBas := 0
				If U25->(FieldPos("U25_DESPBA"))>0
					If cFilAnt <> QRY->FILIAL
						cFilAnt := QRY->FILIAL
						//lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA
						lNgDesc := Eval(bGetMvFil, "MV_XNGDESC")
					EndIf
					nPrcBas := U_URetPrBa(QRY->CODIGO_PRODUTO, QRY->FORMA, QRY->CONDPAG, QRY->ADMINST, 0, STOD(QRY->DATA_INI_VIGENCIA), QRY->HORA_INI_VIGENCIA)
				EndIf

				// aPrecos - [01]-FILIAL,[02]-FORMA,[03]-CONDICAO,[04]-PRODUTO,[05]-DESCRICAO,[06]-PRC BASE,[07]-PRC VENDA,[08]-DESC/ACRES,[09]-DT VIGENCIA,[10]-HR VIGENCIA
				// aPrecos - [01]-FILIAL,[02]-FORMA,[03]-CONDICAO,[04]-PRODUTO,[05]-DESCRICAO,[06]-PRC VENDA,[07]-DT VIGENCIA,[08]-HR VIGENCIA
				aadd(aPrecos, QRY->FILIAL)
				aadd(aPrecos, cDescFr)
				aadd(aPrecos, cDescCd)
				aadd(aPrecos, QRY->CODIGO_PRODUTO)
				aadd(aPrecos, QRY->DESCRICAO_PRODUTO)
				If U25->(FieldPos("U25_DESPBA"))>0
					aadd(aPrecos, nPrcBas) //-- preço base
				EndIf
				If U25->(FieldPos("U25_DESPBA"))>0
					If lNgDesc //QRY->DESCONTO <> 0
						aadd(aPrecos, nPrcBas - QRY->DESCONTO) //-- preço negociado
						aadd(aPrecos, QRY->DESCONTO) //-- desconto/acrescimo
					Else
						aadd(aPrecos, QRY->VALOR) //-- preço negociado
						aadd(aPrecos, nPrcBas - QRY->VALOR) //-- desconto/acrescimo
					EndIf
				Else
					aadd(aPrecos, QRY->VALOR) //-- preço negociado
				EndIf
				aadd(aPrecos, STOD(QRY->DATA_FIM_VIGENCIA))
				aadd(aPrecos, QRY->HORA_FIM_VIGENCIA)

				aadd(aRet,aPrecos)

				QRY->(DbSkip())

			EndDo

		Else
			If U25->(FieldPos("U25_DESPBA"))>0
				aadd(aRet,{"","","","","",0,0,0,"",""})
			Else
				aadd(aRet,{"","","","","",0,"",""})
			EndIf

		EndIf

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		EndIf

	Else
		If U25->(FieldPos("U25_DESPBA"))>0
			aadd(aRet,{"","","","","",0,0,0,"",""})
		Else
			aadd(aRet,{"","","","","",0,"",""})
		EndIf

	EndIf

	cFilAnt := cFilBkp
	RestArea(aArea)

Return(aRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³BuscaFiliaisº Autor ³ Wellington Gonçalves º Data³18/09/2015º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Consulta as filiais da empresa 02						  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                	  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function BuscaFiliais()

	Local aRet			:= {}
	Local aFiliais		:= {}
	Local aArea			:= GetArea()
	Local aAreaSM0		:= SM0->(GetArea())
	Local cUnidade		:= AllTrim(cEmpAnt) // grupo logado (postos)

	SM0->(DbGoTop())

	While SM0->(!Eof())

		aFiliais := {}

		if AllTrim(SM0->M0_CODIGO) $ cUnidade

			aadd(aFiliais, "OK" ) // posição para ficar gravado o status do check
			aadd(aFiliais, AllTrim(SM0->M0_CODFIL) )
			aadd(aFiliais, AllTrim(SM0->M0_FILIAL) )
			aadd(aFiliais, AllTrim(SM0->M0_CIDCOB) )

			aadd(aRet,aFiliais)

		endif

		SM0->(DbSkip())

	EndDo

	if Empty(aRet)
		aadd(aRet,{"","","",""})
	endif

	RestArea(aArea)
	RestArea(aAreaSM0)

Return(aRet)

/*/{Protheus.doc} TRETA41C
Tela de filtro de grupo, cliente, veiculo e motorista.

@author Wellington Gonçalves
@since 18/04/2016
@version 1.0

@return ${return}, ${return_description}

@param cGrupo, characters, grupo de cliente
@param cCliente, characters, cliente
@param cLoja, characters, loja
@param cMotorista, characters, cpf motorista
@param cPlaca, characters, placa

@type function
/*/
User Function TRETA41C(cGrupo,cCliente,cLoja,cMotorista,cPlaca)

	Local aArea := GetArea()
	Local oButton1
	Local oButton2
	Local oButton3
	Local oButton4
	Local oGroup1
	Local oGroup2
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oSay7
	Local oPanel
	Local oDlg
	Local nColorPanel 		:= 14803425
	Local nColorSay			:= 0
	Local oFntGroup			:= TFont():New("Swis721 Cn BT",,20,,.T.,,,,,.F.,.F.)
	Local oFntGet	 		:= TFont():New("Verdana",,013,,.T.,,,,,.F.,.F.)
	Local oFonteSay			:= TFont():New("Verdana",,022,,.F.,,,,,.F.,.F.)
	Local oFonteGet			:= TFont():New("Verdana",,016,,.F.,,,,,.F.,.F.)
	Local nLinha			:= 005
	Local lRet				:= .F.
	Private cGetGrupo 		:= PADR(cGrupo,TamSX3("ACY_GRPVEN")[1])
	Private cGetCliente		:= PADR(cCliente,TamSX3("A1_COD")[1])
	Private cGetLoja		:= PADR(cLoja,TamSX3("A1_LOJA")[1])
	Private cGetPlaca		:= PADR(cPlaca,TamSX3("DA3_PLACA")[1])
	Private cGetMotorista	:= PADR(cMotorista,TamSX3("DA4_CGC")[1])
	Private oGetGrupo
	Private oGetCliente
	Private oGetLoja
	Private oGetPlaca
	Private oGetMotorista

	DEFINE MSDIALOG oDlg TITLE "Filtro" FROM 000, 000  TO 330, 300 PIXEL

// crio o panel para mudar a cor da tela
	@ 0, 0 MSPANEL oPanel SIZE 153, 173 OF oDlg

	@ nLinha, 005 GROUP oGroup1 TO nLinha + 130,147 PROMPT "" OF oPanel PIXEL

	nLinha += 10

	@ nLinha, 010 SAY oSay1 PROMPT "Grupo:" SIZE 100, 010 OF oPanel FONT oFonteSay PIXEL
//@ nLinha - 2, 060 MSGET oGetGrupo VAR cGetGrupo F3 "ACY" SIZE 080, 015 OF oPanel PICTURE "@!" Valid(ValidaCli()) PIXEL  
	oGetGrupo := TGet():New( nLinha - 2, 060,{|u| iif( PCount()==0,cGetGrupo,cGetGrupo:=u) },oPanel, 080, 015, "@!",{|| ValidaCli() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGetGrupo",,,,.T.,.F.)

//criando objeto de pesquisa
	TSearchF3():New(oGetGrupo,400,250,"ACY","ACY_GRPVEN",{{"ACY_DESCRI",3},{"ACY_GRPVEN",1}},"",{{"ACY_GRPVEN","ACY_DESCRI"},{"ACY_GRPVEN","ACY_DESCRI"}},.F.,1,-75,.T.,)

	nLinha += 25

	@ nLinha, 010 SAY oSay2 PROMPT "Cliente:" SIZE 100, 010 OF oPanel FONT oFonteSay PIXEL
//@ nLinha - 2, 060 MSGET oGetCliente VAR cGetCliente F3 "SA1" SIZE 050, 015 OF oPanel PICTURE "@!" Valid(ValidaCli()) PIXEL               
//@ nLinha - 2, 115 MSGET oGetLoja VAR cGetLoja SIZE 025, 015 OF oPanel PICTURE "@!" Valid(ValidaCli()) PIXEL     
	oGetCliente := TGet():New( nLinha - 2, 060,{|u| iif( PCount()==0,cGetCliente,cGetCliente:=u) },oPanel, 050, 015, "@!",{|| ValidaCli() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGetCliente",,,,.T.,.F.)
	oGetLoja := TGet():New( nLinha - 2, 115,{|u| iif( PCount()==0,cGetLoja,cGetLoja:=u) },oPanel, 025, 015, "@!",{|| ValidaCli() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGetLoja",,,,.T.,.F.)

//criando objeto de pesquisa
	TSearchF3():New(oGetCliente,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN","A1_CGC"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN","A1_CGC"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN","A1_CGC"}},.F.,1,-75,.T.,{{oGetLoja,"A1_LOJA"}})

	nLinha += 25

	@ nLinha, 010 SAY oSay3 PROMPT "Veículo:" SIZE 100, 010 OF oPanel FONT oFonteSay PIXEL
	@ nLinha - 2, 060 MSGET oGetPlaca VAR cGetPlaca F3 "DA302" SIZE 080, 015 OF oPanel PICTURE PesqPict("DA3","DA3_PLACA") Valid(ValidaPlaca()) PIXEL

	nLinha += 25

	@ nLinha, 010 SAY oSay4 PROMPT "Motorista:" SIZE 100, 010 OF oPanel FONT oFonteSay PIXEL
	@ nLinha - 2, 060 MSGET oGetMotorista VAR cGetMotorista F3 "DA402" SIZE 080, 015 OF oPanel PICTURE "@R 999.999.999-99" PIXEL

	nLinha += 25

// BOTAO LIMPAR
//oButton2 := TBTNPDV():New(nLinha,102,74/2,24/2,oPanel,"PCLBTNLIMP.png", {|| (LimpaFiltro())}, "Limpar")
	oButton2 := TButton():New( nLinha,;
		102,;
		"Limpar",;
		oPanel,;
		{|| (LimpaFiltro())},;
		74/2,;
		26/2,;
		,,,.T.,;
		,,,{|| .T.})
	oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_FOCAL ))

	nLinha += 27

// BOTAO CONFIRMAR
//oButton3 := TBTNPDV():New(nLinha,092,110/2,36/2,oPanel,"PCLBTNCONF.png", {|| iif( ConfirmaDados(@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca), (lRet := .T.,oDlg:End()), )}, "Confirmar")
	oButton3 := TButton():New( nLinha,;
		092,;
		"Confirmar",;
		oPanel,;
		{|| iif( ConfirmaDados(@cGrupo,@cCliente,@cLoja,@cMotorista,@cPlaca), (lRet := .T.,oDlg:End()), )},;
		110/2,;
		36/2,;
		,,,.T.,;
		,,,{|| .T.})
	oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))

// BOTAO CANCELAR
//oButton4 := TBTNPDV():New(nLinha,032,110/2,36/2,oPanel,"PCLBTNCANC.png", {|| oDlg:End()}, "Cancelar")
	oButton4 := TButton():New( nLinha,;
		032,;
		"Cancelar",;
		oPanel,;
		{|| oDlg:End()},;
		110/2,;
		36/2,;
		,,,.T.,;
		,,,{|| .T.})
	oButton4:SetCSS( POSCSS (GetClassName(oButton4), CSS_BTN_FOCAL ))

	ACTIVATE MSDIALOG oDlg CENTERED

	RestArea(aArea)

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ LimpaFiltroºAutor³Wellington Gonçalvesº Data ³  18/04/2016 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que limpa o filtro						          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function LimpaFiltro()

// atualizo as variáveis dos MSGET's
	cGetGrupo 		:= SPACE(TamSX3("ACY_GRPVEN")[1])
	cGetCliente		:= SPACE(TamSX3("A1_COD")[1])
	cGetLoja		:= SPACE(TamSX3("A1_LOJA")[1])
	cGetPlaca		:= SPACE(TamSX3("DA3_PLACA")[1])
	cGetMotorista	:= SPACE(TamSX3("DA4_CGC")[1])

// faço um refresh nos MSGET's
	oGetGrupo:Refresh()
	oGetCliente:Refresh()
	oGetLoja:Refresh()
	oGetPlaca:Refresh()
	oGetMotorista:Refresh()

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ConfirmaDadosºAutor³Wellington Gonçalvesº Data ³ 18/04/2016 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que atualiza as entidades					          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function ConfirmaDados(cGrupo,cCliente,cLoja,cMotorista,cPlaca)

	Local lRet := .F.

	if Empty(cGetGrupo) .AND. Empty(cGetCliente) .AND. Empty(cGetMotorista) .AND. Empty(cGetPlaca) // se o usuário não preencheu nenhum parâmetro
		Alert("Informe pelo menos uma entidade!")
	else
		cGrupo 		:= cGetGrupo
		cCliente	:= cGetCliente
		cLoja		:= cGetLoja
		cMotorista	:= cGetMotorista
		cPlaca		:= cGetPlaca
		lRet		:= .T.
	endif

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ ValidaCli º Autor³Wellington Gonçalves º Data ³ 22/04/2016 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função chamada na validação dos campos que consultam		  º±±
±±º          ³ o cliente.								                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function ValidaCli()

	Local aArea			:= GetArea()
	Local aAreaSA1		:= SA1->(GetArea())
	Local aAreaACY		:= ACY->(GetArea())
	Local aAreaDA3		:= DA3->(GetArea())
	Local lRet 			:= .T.

// se o grupo de cliente estiver preenchido e não foi informado o cliente
	If !Empty(cGetGrupo) .AND. Empty(cGetCliente)

		ACY->(DbSetOrder(1)) // ACY_FILIAL + ACY_GRPVEN
		If !ACY->(DbSeek(xFilial("ACY") + cGetGrupo))
			lRet := .F.
			Aviso( "ATENÇÃO", "O grupo de cliente informado é inválido!", {"Ok"} )
		EndIf

	ElseIf !Empty(cGetCliente) .AND. !Empty(cGetLoja) // se os campos do cliente estiverem preenchidos

		SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD
		If SA1->(DbSeek(xFilial("SA1") + cGetCliente + cGetLoja))

			// se o cliente não estiver bloqueado
			If SA1->A1_MSBLQL <> "1"

				// se o grupo estiver preenchido
				If !Empty(cGetGrupo) .AND. cGetGrupo <> SA1->A1_GRPVEN
					lRet := .F.
					Aviso( "ATENÇÃO", "Este cliente não está vinculado a este grupo!", {"Ok"} )
				Else

					// se a placa estiver preenchida
					If !Empty(cGetPlaca)

						// se o cliente restringir veículo, verifico se o cliente está amarrado a esta placa
						If SA1->A1_XRESTRI == "S"

							If !Empty(cGetPlaca)
								DbSelectArea("DA3")
								DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
								If !DA3->(DbSeek(xFilial("DA3")+cGetPlaca )) .OR. !(DA3->DA3_XCODCL+DA3->DA3_XLOJCL==SA1->A1_COD+SA1->A1_LOJA .OR. DA3->DA3_XGRPCL==SA1->A1_GRPVEN )
									lRet := .F.
									//Aviso("Atenção!", "A placa "+cGetPlaca+" informada anteriormente não está vinculada a este cliente! Selecionar outra placa!", {"OK"}, 2)
								EndIf
							EndIf

						EndIf

					EndIf

					If !lRet
						Aviso( "ATENÇÃO", "Esta placa não está vinculada ao cliente informado!", {"Ok"} )
					EndIf

				endif

			Else
				Aviso( "ATENÇÃO", "O cadastro deste cliente está bloqueado!", {"Ok"} )
				lRet := .F.
			EndIf

		else

			Aviso( "ATENÇÃO", "O cliente informado é inválido!", {"Ok"} )
			lRet := .F.

		EndIf

	EndIf

	RestArea(aAreaSA1)
	RestArea(aAreaDA3)
	RestArea(aAreaACY)
	RestArea(aArea)

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ ValidaPlacaºAutor³Wellington Gonçalves º Data ³ 22/04/2016 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função chamada na validação da placa						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function ValidaPlaca()

	Local aArea			:= GetArea()
	Local aAreaDA3		:= DA3->(GetArea())
	Local aAreaSA1		:= SA1->(GetArea())
	Local lRet 			:= .T.

	if !Empty(cGetPlaca)

		DbSelectArea("DA3")
		DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
		If DA3->(DbSeek(xFilial("DA3")+cGetPlaca ))

			If !Empty(cGetCliente) .AND. !Empty(cGetLoja)

				SA1->(DbSetOrder(1))
				If SA1->(DbSeek(xFilial("SA1") + cGetCliente + cGetLoja ))

					// se o cliente tem restrição de veículo
					If SA1->A1_XRESTRI == "S"

						If !(DA3->DA3_XCODCL+DA3->DA3_XLOJCL==SA1->A1_COD+SA1->A1_LOJA .OR. DA3->DA3_XGRPCL==SA1->A1_GRPVEN )
							Aviso( "ATENÇÃO", "Esta placa não está vinculada ao cliente informado!", {"Ok"} )
							lRet := .F.
						EndIf

					EndIf

				EndIf

			EndIf

		Else
			//Aviso( "ATENÇÃO", "A placa informada não está cadastrada!", {"Ok"} )
			//lRet := .F.
		EndIf

	EndIf

	RestArea(aAreaDA3)
	RestArea(aAreaSA1)
	RestArea(aArea)

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ ValidaMot º Autor³Wellington Gonçalves º Data ³ 22/04/2016 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função chamada na validação do motorista					  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function ValidaMot()

	Local lRet 		:= .T.
	Local aArea		:= GetArea()
	Local aAreaDA4	:= DA4->(GetArea())

	if !Empty(cGetMotorista)

		DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
		if !DA4->(DbSeek(xFilial("DA4") + RTrim(cGetMotorista)))
			//Aviso( "", "O motorista informado não está cadastrado!", {"Ok"} )
			//lRet := .F.
		endif

	endif

	RestArea(aAreaDA4)
	RestArea(aArea)

Return(lRet)

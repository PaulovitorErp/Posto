#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'poscss.ch'

/*/{Protheus.doc} TPDVA004
Realiza Flag de Manutenção de Bomba no abastecimento (PDV)

@author pablo
@since 08/11/2018
@version 1.0
@return lRet

@type function
/*/
User Function TPDVA004()

	Local lRet := .T.
	Local nPos, nPosAbast, nPosNum
	Local oGetList
	Local oTelaPDV, cGetFoco
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))
	Local oPnlPrinc, oPanelMnt, oSay1, oGet1
	Local cGetMnt := ""
	Local uResult := Nil
	Local cUsrMnt := ""

	Private oDlgMNT

	if MID->(FieldPos("MID_XMANUT")) == 0
		STFMessage("MANUTBOMB","STOP", "Campo MID_XMANUT não criado!" )
		STFShowMessage("MANUTBOMB")
		Return .F.
	endif

	//verifica se o usuário tem permissão para acesso a rotina
	U_TRETA37B("MATBOM", "MANUTENCAO DE BOMBA NO PDV")
	cUsrMnt := U_VLACESS1("MATBOM", RetCodUsr())
	If cUsrMnt == Nil .OR. Empty(cUsrMnt)
		STFMessage("MANUTBOMB","STOP", "Usuário não tem permissão de acesso a rotina de Manutenção de Bomba." )
		STFShowMessage("MANUTBOMB")
		Return .F.
	EndIf

	DbSelectArea("U00")
	cGetMnt := Space(TamSX3("MID_XMANUT")[1])

	cGetFoco := ReadVar()
	oTelaPDV := STIGetObjTela()

	if oTelaPDV:oOwner:oCtlFocus:cName <> "GRIDABASTECIMENTO" //-- Na Grid de Abastecimento
		if cGetFoco == "CGETSALESMAN"
			STFMessage("MANUTBOMB","STOP", "Necessário posicionar no abastecimento para marcar manutençao!" )
		else
			STFMessage("MANUTBOMB","STOP", "Abra a tela de abastecimentos e posicione no item desejado!" )
		endif
		STFShowMessage("MANUTBOMB")
		Return .F.
	endif

	oGetList := STIGGridAbast() //pega o grid de abastecimentos

	if Valtype(oGetList) == "O"
		if len(oGetList:aCols) > 0 //protecao oGetList vazio

			nPos		:= oGetList:nAt
			nPosAbast := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_CODABA"})
			nPosNum := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_NUMORC"}) 

			//Verifica se informou algum abastecimento para realizar Aferição
			If empty(oGetList:aCols[nPos][nPosAbast]) //oGetList
				lRet := .F.
				STFMessage("MANUTBOMB","STOP", "Necessário posicionar no abastecimento para marcá-lo como manutençao!" )
				STFShowMessage("MANUTBOMB")
			EndIf

			if lRet .AND. oGetList:aCols[nPos][01] == "TICK_VERDE"
				lRet := .F.
				STFMessage("MANUTBOMB","STOP", "O abatecimento posicionado já está lançado na venda! Desmarque-o!" )
				STFShowMessage("MANUTBOMB")
			endif

			if lRet .AND. oGetList:aCols[nPos][nPosNum] == "O" //O=em uso na venda de algum PDV
				lRet := .F.
				STFMessage("MANUTBOMB","STOP", "O abatecimento posicionado está em uso!" )
				STFShowMessage("MANUTBOMB")
			endif

			if lRet
				lRet := .F. //mudo flag para usar no confirmar

				//limpa as tecla atalho
				U_UKeyCtr() 

				DEFINE MSDIALOG oDlgMNT TITLE "" FROM 000, 000  TO 350, 410 COLORS 0, 16777215 PIXEL OF GetWndDefault() STYLE DS_MODALFRAME

				@ 0,0 MSPANEL oPnlPrinc SIZE 300, 300 OF oDlgMNT COLORS 0, cCorBack
				oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT

				// crio o panel para mudar a cor da tela
				@ 4, 0 MSPANEL oPanelMnt SIZE 203, 175 OF oPnlPrinc //COLORS 0, RGB(40,79,102)
				oPanelMnt:SetCSS( POSCSS (GetClassName(oPanelMnt), CSS_PANEL_CONTEXT ))

				@ 010, 010 SAY oSay1 PROMPT "Informar Manutencao de Bomba" SIZE 200, 015 OF oPanelMnt COLORS 0, 16777215 PIXEL
				oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

				@ 030, 010 SAY oSay1 PROMPT ("Dados do Abastecimento:" + CRLF + CRLF + ;
							"Nr Abast.: " + Alltrim(oGetList:aCols[nPos][nPosAbast]) + CRLF + ;
							"Produto: " + Alltrim(oGetList:aCols[nPos][aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MHZ_DESPRO"})]) + CRLF + ;
							"Bico: " + Alltrim(oGetList:aCols[nPos][aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_CODBIC"})]) + CRLF + ;
							"Litros: " + Alltrim(Transform(oGetList:aCols[nPos][aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_LITABA"})],"@E 9,999.999"));
							 ) SIZE 200, 400 OF oPanelMnt COLORS 0, 16777215 PIXEL
				oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))

				@ 105, 010 SAY oSay1 PROMPT "Informe o Num. da Manutenção" SIZE 200, 400 OF oPanelMnt COLORS 0, 16777215 PIXEL
				oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
				@ 115, 010 MSGET oGet1 VAR cGetMnt SIZE 080, 013 OF oPanelMnt F3 "U00" COLORS 0, 16777215 PIXEL HASBUTTON

				// BOTAO CONFIRMAR
				oButton3 := TButton():New(145,;
										150,;
										"&Confirmar",;
										oPanelMnt	,;
										{|| iif(VldTela(cGetMnt, oGet1),(lRet:=.T.,oDlgMNT:End()), ) },;
										45,;
										20,;
										,,,.T.,;
										,,,{|| .T.})
				oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))

				// BOTAO CANCELAR
				oButton4 := TButton():New(145,;
										100,;
										"C&ancelar",;
										oPanelMnt	,;
										{|| oDlgMNT:End()},;
										45,;
										20,;
										,,,.T.,;
										,,,{|| .T.})
				oButton4:SetCSS( POSCSS (GetClassName(oButton4), CSS_BTN_ATIVO ))

				ACTIVATE MSDIALOG oDlgMNT CENTERED

				//restaura as teclas atalho
				U_UKeyCtr(.T.) 

				if lRet
					//se o abastecimento tem na base dbf, altero ele tbm
					U_TPA004GR(oGetList:aCols[nPos][nPosAbast], cGetMnt)

					//altero na central PDV
					aParam := {oGetList:aCols[nPos][nPosAbast],cGetMnt,.T. }
					aParam := {"U_TPA004GR",aParam}
					if FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam, NIL, .T., @uResult)
						If uResult
							oGetList:oBrowse:Refresh()

							STFMessage("MANUTBOMB","ALERT", "Manutençao vinculada ao abastecimento com sucesso!" )
							STFShowMessage("MANUTBOMB")
						else
							STFMessage("MANUTBOMB","STOP", "Não foi possível marcar a manutenção de bomba!" )
							STFShowMessage("MANUTBOMB")
						endif
					else
						STFMessage("MANUTBOMB","STOP", "Não foi possível marcar a manutenção de bomba!" )
						STFShowMessage("MANUTBOMB")
					endif
				endif
			endif
		else
			STFMessage("MANUTBOMB","STOP", "Necessário posicionar no abastecimento para realizar a manutenção de bomba!" )
			STFShowMessage("MANUTBOMB")
		endif
	else
		STFMessage("MANUTBOMB","STOP", "Acione a tela de abastecimentos pendentes!" )
		STFShowMessage("MANUTBOMB")
	endif

Return lRet

//----------------------------------------------
// faz validaçao da tela
//----------------------------------------------
Static Function VldTela(cCodMnt, oGet1)

	Local lRet := .T.

	if empty(cCodMnt)
		MsgInfo("Informe o codigo da manutenção!","Atenção")
		lRet := .F.
	elseif !ExistCpo("U00",cCodMnt)
		lRet := .F.
	endif

	if !lRet
		oGet1:SetFocus()
	endif

Return lRet

/*/{Protheus.doc} TPA004GR
Faz a gravaçao do flag no abastecimento
@author thebr
@since 26/12/2018
@version 1.0
@return lRet

@type function
/*/
User Function TPA004GR(cCodigo, cCodMnt, lIntegra)

	Local lRet := .F.
	//Local aSLI := {}

	DEFAULT lIntegra := .F.

	//conout("TPA004GR inicio")

	MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
	If MID->( DbSeek( xFilial("MID") + cCodigo ) ) .and. Reclock("MID", .F.)

		//conout("TPA004GR entrou no if da MID/reclock")

		MID->MID_XMANUT := cCodMnt

		//-- Mudou o Status deve integrar na retaguarda quando for finalização de venda
		if lIntegra

			//conout("TPA004GR entrou no if da integracao")

			/*aSLI := {{"LI_FILIAL"		,	xFilial("SLI")						}	,;
					{"LI_ESTACAO"		,	""									}	,;
					{"LI_TIPO"			,	"UP"								}	,;
					{"LI_USUARIO"		,	UsrRetName( RetCodUsr() )			}	,;
					{"LI_DATA"			,	dDataBase							}	,;
					{"LI_HORA"			,	Time()								}	,;
					{"LI_MSG"			,	MID->MID_FILIAL + MID->MID_CODABA   }	,;
					{"LI_ALIAS"			,	"MID"								}	,;
					{"LI_UPREC"			,	MID->( RecNo() )					}	,;
					{"LI_FUNC"			,	""									}	}

			STFSaveTab("SLI", aSLI, .T., .F.)*/

			MID->MID_SITUA := "00"

		endif

		MID->( MsUnLock() )

		lRet := .T.

	Endif
	//conout("TPA004GR fim")

Return lRet

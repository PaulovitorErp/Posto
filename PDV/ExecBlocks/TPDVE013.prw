#INCLUDE "Protheus.ch"
#INCLUDE "Topconn.Ch"
#include 'poscss.ch'

Static cVendedor := "" //VENDEDOR ATUAL LOGADO
Static cNomeVend := ""

/*/{Protheus.doc} TPDVE013
Rotina de controle Senha por Vendedor - Tela Bloqueio

@author Danilo Brito
@since 03/05/2019
@version 1.0

@return ${return}, ${return_description}

@type function
/*/

User Function TPDVE013()  

    Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
    Local cMvCpSenha := SuperGetMv("TP_CPSWVEN",,"A3_SENHA")
    Local aRes := GetScreenRes()
	Local nWidth, nHeight
    Local oPnlPrinc, oPnlForm
	Local oSay1
	Local oSay2
	Local lOpenCash := STBOpenCash()

	Private oGetUser
	Private oGetSenha
	Private cGetUser 		:= Space(TamSX3("A3_COD")[1])
	Private cGetSenha		:= Space(TamSX3(cMvCpSenha)[1])
    Private oDlgLogin
    Private bLogin := {|| iif(DoLogin(), lEndDlg := .T., ), iif(lEndDlg, oDlgLogin:End(), ) }
    Private bCloseTela := {|| DoClose() }
    Private aSavKeys := {}
	Private oSayErr
	Private lEndDlg := .F.

	If !lOpenCash
		Return .F.
	EndIf

    //Caso não ativado senha, trabalha com vendedor do caixa ou padrao 
    If !lMvPswVend
        SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
        If SA3->(DbSeek(xFilial("SA3") + RETCODUSR()))
            cVendedor := SA3->A3_COD
        Else
            SA3->(DbSetOrder(1))
            If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
                cVendedor := SA3->A3_COD
            EndIf
        EndIf
        Return .F.
    EndIf

	//Limpar Tela (SHIFT+F3), evitar de abastecimentos ficarem presos...
	//Ticket: POSTO-741 - Abastecimentos retornam pra tela - Sereia - 17/02/23
	If !(U_TPDVP02A())
		Return .F.
	EndIf

    //limpa as tecla atalho
	U_UKeyCtr() 

	While !lEndDlg

		DEFINE DIALOG oDlgLogin TITLE "login" PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)
		oDlgLogin:lEscClose := .F.
		oDlgLogin:nWidth := aRes[1]
		oDlgLogin:nHeight := aRes[2]
		nWidth := aRes[1]/2
		nHeight := aRes[2]/2

		//pnl Principal
		@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgLogin
		oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlPrinc:SetCSS( POSCSS(GetClassName(oPnlPrinc), CSS_BG ) )

		//Painel Form
		@ ((nHeight-300)/2),((nWidth-200)/2) MSPANEL oPnlForm SIZE 200, 300 OF oPnlPrinc
		//oPnlForm:SetCSS( "TPanel{ background-color: #F4F4F4; border-radius: 8px; border: 1px solid #F4F4F4;}" )
		oPnlForm:SetCSS( POSCSS (GetClassName(oPnlForm), CSS_PANEL_CONTEXT ))

		@ 020, 055 REPOSITORY oLogo SIZE 100, 100 OF oPnlForm PIXEL NOBORDER
		oLogo:LoadBmp("FWSKIN_LOGO_TOTVS_BLACK.PNG")

		@ 060, 005 SAY Replicate("_",200) SIZE 192, 008 OF oPnlForm FONT COLORS CLR_HGRAY, 16777215 PIXEL

		@ 080, 020 SAY oSay1 PROMPT "Bloqueio de Tela" SIZE 100, 015 OF oPnlForm PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 110, 020 SAY oSay1 PROMPT "Identifique-se abaixo para usar as operações de PDV, de forma que fiquem vinculadas ao seu ID." SIZE 160, 050 OF oPnlForm PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_HEADER ))
		
		@ 155, 020 SAY oSay1 PROMPT "Id Vendedor:" SIZE 100, 007 OF oPnlForm PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
		@ 165, 020 MSGET oGetUser VAR cGetUser SIZE 160, 013 OF oPnlForm COLORS 0, 16777215 PIXEL VALID VldCpVend()
		oGetUser:SetCSS( POSCSS (GetClassName(oGetUser), CSS_GET_NORMAL ))

		@ 185, 020 SAY oSay2 PROMPT "Senha:" SIZE 100, 007 OF oPnlForm PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
		@ 195, 020 MSGET oGetSenha VAR cGetSenha SIZE 160, 013 Password OF oPnlForm COLORS 0, 16777215 PIXEL
		oGetSenha:SetCSS( POSCSS (GetClassName(oGetSenha), CSS_GET_NORMAL ))

		@ 220, 020 SAY oSayErr PROMPT "" SIZE 160, 020 OF oPnlForm COLORS CLR_RED, 16777215 PIXEL

		@ 245, 005 SAY Replicate("_",200) SIZE 192, 008 OF oPnlForm FONT COLORS CLR_HGRAY, 16777215 PIXEL

		oBtn1 := TButton():New(265,140,"Entrar",oPnlForm ,bLogin,050,020,,,,.T.,,,,{|| .T.})
		oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

		oBtn2 := TButton():New(265,085,"Sair",oPnlForm ,bCloseTela,050,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

		ACTIVATE DIALOG oDlgLogin CENTER

		oDlgLogin := Nil

	EndDo
	
	//restaura as teclas atalho
	U_UKeyCtr(.T.) 

Return .F.

Static Function VldCpVend()

	if !empty(cGetUser)
		cGetUser := padl(AllTrim(cGetUser),tamsx3("A3_COD")[1],"0")
		oGetUser:Refresh()
	endif

Return .T.


Static Function DoLogin()
	
	Local aArea		:= GetArea()
	Local cMvCpSenha := SuperGetMv("TP_CPSWVEN",,"A3_SENHA")
	Local lRet := .T.
	Local oTelaPDV

	if empty(cGetUser)
		oSayErr:SetText("Informe um codigo de vendedor!")
		lRet := .F.
	endif
	if lRet .AND. empty(cGetSenha)
		oSayErr:SetText("Informe a senha!")
		lRet := .F.
	endif

	if lRet
		SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
		if !SA3->(DbSeek(xFilial("SA3")+cGetUser))
			oSayErr:SetText("Vendedor inválido!")
			lRet := .F.
		else
			if Empty(SA3->&(cMvCpSenha) )
				oSayErr:SetText("Senha não cadastrada para o vendedor "+AllTrim(SA3->A3_COD)+" - "+AllTrim(SA3->A3_NOME)+"!")
				lRet := .F.
			else
				if AllTrim(cGetSenha) <> AllTrim(SA3->&(cMvCpSenha))
					oSayErr:SetText("Senha inválida!")
					lRet := .F.
				endif
			endif
		endif
	endif

	if lRet
		cVendedor := SA3->A3_COD
		cNomeVend := SA3->A3_NOME
		
		//Seta informacoes no topo da tela PDV
    	oTelaPDV := STIGetObjTela() //pego objeto da tela
		oTelaPDV:SetTInfo( "PDV: " + cEstacao + "    |    Operador: " + cUserName + space(6) +"."+ chr(13)+chr(10) + "Vendedor: " + Alltrim(cNomeVend) + space(7))
		
		//reset da tela Painel Posto - Quando troca vendedor
		cFunPnlPosto := U_TpGetFClear()
		if !empty(cFunPnlPosto)
			ExecBlock(cFunPnlPosto ,.F.,.F.) 
		endif

	endif

	oSayErr:Refresh()
	RestArea(aArea)

Return lRet

Static Function DoClose()
	Local lClsSys := SuperGetMv("TP_EXITSYS",,.T.)

	if lClsSys 
		if MsgYesNo("Deseja realmente sair do sistema?")
			ExecBlock("TPDVP018",.F.,.F., .T.)
		endif
	else
		//oDlgLogin:End()
	endif

Return

//Metodo para pegar o vendedor logado
//1=codigo; 2=nome
User Function TPGetVend(nTipo)
	Local cRet := cVendedor
	DEFAULT nTipo := 1

	if nTipo == 2
		cRet := cNomeVend
	endif
Return cRet

//Metodo para saber se tem vendedor logado
User Function TPVendOn()
Return !empty(cVendedor)

//-------------------------------------------------------------------
/*/{Protheus.doc} TpAtuVend
Ajuste do vendedor da SL1
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TpAtuVend()
	
	SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
	SA3->(DbSeek(xFilial("SA3")+U_TPGetVend() ))
	oModelVen := STWSalesmanSelection(SA3->A3_COD)
	STDSPBasket("SL1","L1_VEND", oModelVen:GetValue("SA3MASTER","A3_COD"))
	STDSPBasket("SL1","L1_COMIS", STDGComission( oModelVen:GetValue("SA3MASTER","A3_COD") ))

Return

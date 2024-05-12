#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA32
Cadastro de Requisições
@author Danlo Brito
@since 26/04/2019
@version 1.0
@return Nil
@type function
/*/
user function TRETA032()

	Local oBrowse
	Private cCadastro := 'Cadastro de Requisições'

	DbSelectArea("U56")
	DbSelectArea("U57")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('U56')
	oBrowse:SetDescription(cCadastro)

	oBrowse:AddLegend( "U56_STATUS == 'L'", "GREEN",  "Liberada" ) //Pre e Pos Paga ja gerado o Financeiro
	oBrowse:AddLegend( "U56_STATUS == 'N'", "BLACK",  "Deposito Não Identificado" ) //Pre nao identificada

	oBrowse:Activate()

return

/*/{Protheus.doc} MenuDef
Definicao do menu da rotina requisições

@author thebr
@since 26/04/2019
@version 1.0
@return aRotina
@type function
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'    ACTION 'VIEWDEF.TRETA032' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'       ACTION 'VIEWDEF.TRETA032' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'       ACTION 'VIEWDEF.TRETA032' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'       ACTION 'VIEWDEF.TRETA032' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'      ACTION 'VIEWDEF.TRETA032' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Liberar Requisição Pré-Paga'      ACTION 'U_TRETA32A()'     OPERATION 10 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir Requisições'     		ACTION 'U_TRETR010(.F.,"","")'     OPERATION 10 ACCESS 0
	ADD OPTION aRotina TITLE 'Enviar Requisições' 				ACTION 'MsAguarde({|| U_TRETR010(.T.,"","") },"Aguarde","Enviando E-mail...",.T.)' OPERATION 10 ACCESS 0
	ADD OPTION aRotina TITLE 'Legenda'       ACTION 'U_TRETA32L()'     OPERATION 10 ACCESS 0

Return aRotina

/*/{Protheus.doc} ModelDef
Dfinição do Model
@author thebr
@since 26/04/2019
@version 1.0
@return oModel
@type function
/*/
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruU56 := FWFormStruct( 1, 'U56', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU57 := FWFormStruct( 1, 'U57', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM032', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo (header da grid)
	oModel:AddFields( 'U56MASTER', /*cOwner*/, oStruU56, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U56_FILIAL", "U56_PREFIX", "U56_CODIGO" })

	// Adiciona ao modelo uma componente de grid
	oModel:AddGrid( 'U57DETAIL', 'U56MASTER', oStruU57 )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'U57DETAIL', { {'U57_FILIAL', 'xFilial( "U57" )'}, {'U57_PREFIX', 'U56_PREFIX'}, {'U57_CODIGO', 'U56_CODIGO'} }, U57->( IndexKey( 1 ) )  )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'U57DETAIL' ):SetUniqueLine( { 'U57_PARCEL' } )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Modelo de Dados de Requisições' )

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'U56MASTER' ):SetDescription( 'Cabeçalho da Requisição' )
	oModel:GetModel( 'U57DETAIL' ):SetDescription( 'Parcelas' )

Return oModel

/*/{Protheus.doc} ViewDef
Definicao da camada Visao
@author thebr
@since 26/04/2019
@version 1.0
@return oView
@type function
/*/
Static Function ViewDef()

	Local oModel   := FWLoadModel( 'TRETA032' )
	Local oStruU56 := FWFormStruct( 2, 'U56' )
	Local oStruU57 := FWFormStruct( 2, 'U57' )
	Local oView

	//Remove campos da estrutura
	oStruU57:RemoveField( 'U57_PREFIX' )
	oStruU57:RemoveField( 'U57_CODIGO' )

	// Cria o objeto de View
	oView := FWFormView():New()                                                        '

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U56', oStruU56, 'U56MASTER' )

	//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_U57', oStruU57, 'U57DETAIL' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 55 )
	oView:CreateHorizontalBox( 'INFERIOR'    , 45 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_U56' , 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_U57' , 'INFERIOR' )

	// titulo dos componentes
	oView:EnableTitleView('VIEW_U56' ,/*'cabecalho'*/)
	oView:EnableTitleView('VIEW_U57' ,/*'parcelas'*/)

	// Define campos que terao Auto Incremento
	oView:AddIncrementField( 'VIEW_U57', 'U57_PARCEL' )

Return oView

/*/{Protheus.doc} TRETA32L
Definicao da legenda
@author thebr
@since 26/04/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETA32L()

	Local aLegenda := {}

	aadd(aLegenda, {"BR_VERDE",    "Liberada"} ) //requisições liberadas (ja disponibilizados os creditos)
	aadd(aLegenda, {"BR_PRETO",    "Deposito Não Identificado"} ) //requisições do tipo PRE-PAGA ainda nao identificadas

	BrwLegenda("Cadastro de Requisições",    "Legenda", aLegenda)

Return

/*/{Protheus.doc} TRETA32A
Rotina de liberação de Requisições Pré Paga

@author thebr
@since 26/04/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETA32A()

	Local aAreaU56 := U56->(GetArea())
	Local cMsgFin := ""
	Local cQuebra := chr(13)+chr(10)
	Local nOpcx := 0
	Local lContinua := .T.

	//TODO: Criar permissão de acesso (perfil)

	if U56->U56_STATUS == "L"
		MsgInfo("A Requisição já liberada!", "Atenção")
		lContinua := .F.
	else
		//verifica se pode gerar o financeiro
		U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
		U57->(DbSeek( U56->U56_FILIAL+U56->U56_PREFIX+U56->U56_CODIGO ))
		while U57->(!EOF()) .and. U57->U57_FILIAL+U57->U57_PREFIX+U57->U57_CODIGO == U56->U56_FILIAL+U56->U56_PREFIX+U56->U56_CODIGO
			if !Empty(U57->U57_XGERAF)
				MsgInfo("A Requisição não se trata de um depósito da retaguarda!", "Atenção")
				lContinua := .F.
			endif
			U57->(DbSkip())
		enddo

	endif

	if lContinua
		if U56->U56_TIPO == "1"

			cMsgFin := "Esta opção irá fazer a liberação da Requisição! "+cQuebra+cQuebra
			cMsgFin += "Escolha uma das opções:"+cQuebra
			cMsgFin += "1 = Gerar Titulo de crédito RA a partir da requisição "+cQuebra
			cMsgFin += "2 = Vincular Titulo de crédito já existente à requisição" + cQuebra + cQuebra

			nOpcx := Aviso("Liberação", cMsgFin, {"2-Vincular", "Cancelar", "1-Gerar"}, 2)

			if nOpcx == 3//MsgYesNo("Confirma a geração do(s) título(s) do tipo RA para a requisição Pré-Paga?","Atenção - Req. Pré-Paga")
				GeraSE1RPR() //gera financeiro para as requisições pre-paga
			elseif nOpcx == 1
				VinculaSE1()
			endif
		elseif U56->U56_TIPO == "2"

			MsgInfo("Requisições Pós-Paga não necessitam de liberação!","Atenção")
			Reclock("U56", .F.)
				U56->U56_STATUS := "L"
			U56->(MsUnlock())

		endif
	endif

	RestArea(aAreaU56)

Return

/*/{Protheus.doc} GeraSE1RPR
Geração do financeiro da requisição Pós Paga
@author thebr
@since 26/04/2019
@version 1.0
@return Nil
@param lJob, logical, define se está sendo executado via JOB
@type function
/*/
Static Function GeraSE1RPR(lJob)

	Local aArea		:= GetArea()
	Local aAreaSM0  := SM0->(GetArea())
	Local cNatRa	:= SuperGetMV( "MV_XNATRA" , .T./*lHelp*/, "OUTROS" /*cPadrao*/)
	Local cNatRaPad	:= SuperGetMV( "MV_XNATRAP" , .T./*lHelp*/, "" /*cPadrao*/)
	Local lReqCliPad := SuperGetMv("MV_XRQCPAD",,.F.) //permite requsição para cliente padrao? 
	Local lErro		:= .F.
	Local cFilBkp 	:= cFilAnt
	Local lRet 		:= .F.
	Local aFin040
	Local dBkpDtBs  := dDataBase
	Default lJob	:= .F.

	DbSelectArea("SE1")
	DbSelectArea("U57")

	dDataBase := U56->U56_DTEMIS

	//substituo a natureza caso a requisiçao seja para cliente padrão
	if lReqCliPad .AND. IsCliPad(U56->U56_CODCLI, U56->U56_LOJA) .AND. !empty(cNatRaPad)
		cNatRa := cNatRaPad
	endif

	//Geração dos NCC's, conforme as parcelas U57
	U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	U57->(DbSeek( U56->U56_FILIAL+U56->U56_PREFIX+U56->U56_CODIGO ))
	While U57->(!EOF()) .and. U57->U57_FILIAL+U57->U57_PREFIX+U57->U57_CODIGO == U56->U56_FILIAL+U56->U56_PREFIX+U56->U56_CODIGO

		aFin040 := {}

		//posiciona na filial conforme o prefixo
		DbSelectArea("SM0")
		If (SubStr(U57->U57_PREFIX,2,TamSx3("U57_FILIAL")[1]) <> AllTrim(cFilAnt)) .or. (SubStr(U57->U57_PREFIX,2,TamSx3("U57_FILIAL")[1]) <> SM0->M0_CODFIL)
			If SM0->(DbSeek(cEmpAnt+SubStr(U57->U57_PREFIX,2,TamSx3("U57_FILIAL")[1])))
				cFilAnt := SubStr(U57->U57_PREFIX,2,TamSx3("U57_FILIAL")[1])
			EndIf
		EndIf
		
		//RegToMemory("SE1")

		AADD( aFin040, {"E1_FILIAL"  , xFilial("SE1")  ,Nil})
		AADD( aFin040, {"E1_PREFIXO" , "RPR"           ,Nil}) //REQUISICAO PRE PAGA
		AADD( aFin040, {"E1_NUM"     , SubStr(U57->U57_PREFIX,1,1) + U57->U57_CODIGO ,Nil})
		AADD( aFin040, {"E1_PARCELA" , U57->U57_PARCEL ,Nil})
		AADD( aFin040, {"E1_TIPO"    , "RA "           ,Nil})
		AADD( aFin040, {"E1_NATUREZ" , cNatRa          ,Nil})
		AADD( aFin040, {"CBCOAUTO"   , U56->U56_BANCO  ,Nil}) //-> E1_PORTADO
		AADD( aFin040, {"CAGEAUTO"   , U56->U56_AGENCI ,Nil}) //-> E1_AGEDEP
		AADD( aFin040, {"CCTAAUTO"   , U56->U56_NUMCON ,Nil}) //-> E1_CONTA
		//AADD( aFin040, {"E1_PORTADO" , U56->U56_BANCO  ,Nil})
		//AADD( aFin040, {"E1_AGEDEP"  , U56->U56_AGENCI ,Nil})
		//AADD( aFin040, {"E1_CONTA"   , U56->U56_NUMCON ,Nil})
		AADD( aFin040, {"E1_CLIENTE" , U56->U56_CODCLI ,Nil})
		AADD( aFin040, {"E1_LOJA"    , U56->U56_LOJA   ,Nil})
		If SE1->(FieldPos("E1_DTLANC")) > 0
			AADD( aFin040, {"E1_DTLANC"	 , U56->U56_DTEMIS ,Nil})
		Endif
		AADD( aFin040, {"E1_EMISSAO" , U56->U56_DTEMIS ,Nil})
		AADD( aFin040, {"E1_VENCTO"  , U56->U56_DTEMIS ,Nil})
		AADD( aFin040, {"E1_VENCREA" , DataValida(U56->U56_DTEMIS),Nil})
		AADD( aFin040, {"E1_VALOR"   , U57->U57_VALOR  ,Nil})
		AADD( aFin040, {"E1_HIST"    , "DOC.: "+U56->U56_HIST ,Nil})
		AADD( aFin040, {"E1_ORIGEM"  , "TRETA032"      ,Nil})
		AADD( aFin040, {"E1_XPLACA"	 , U57->U57_PLACA  ,Nil})
		AADD( aFin040, {"E1_XCODBAR" , AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL) ,Nil } ) //codigo de barras da requisição == chave do registro U57

		//Chama Execauto
		lMsErroAuto := .F.
		lMsHelpAuto := .T.
		MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 3)

		If lMsErroAuto
			If lJob
				cErroExec := MostraErro("\temp")
				//Conout(" ============ ERRO =============")
				//Conout(cErroExec)
				cErroExec := ""
			Else
				MostraErro()
			EndIf
			lErro := .T.
		Else
			DbCommitAll()
			lRet := .T.
		EndIf

		U57->(DbSkip())
	EndDo

	dDataBase := dBkpDtBs

	If !lErro
		//Altera o status da requisição para Liberado
		dbselectarea("U56")
		RecLock("U56")
			U56->U56_STATUS := "L"
		U56->(msunlock())

		If !lJob
			MsgInfo("Liberação Efetuada com Sucesso!","Atenção")
		EndIf
	EndIf

	cFilAnt := cFilBkp //sempre volto filial

	RestArea(aAreaSM0)
	RestArea(aArea)

Return lRet

//------------------------------------------------------------------
// Vincula um titulo de credito a requisição
//------------------------------------------------------------------
Static Function VinculaSE1()

	Local lOK := .T.
	Local aTitGrv := {}
	Local aHeaderEx
	Local aColsEx := {}
	Local aAlterFields := {}
	Local aCamposDet := {"MARK","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","E1_SALDO","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_EMISSAO"}
	Local nOpcx := 0
	Local nPosAux := 0
	Local oSay1,oSay2,oSay3,oSay4
	Local oGet1,oGet2,oGet3,oGet4
	Local oButton1,oButton2
	Local cQry, nX
	Private oDlgVinc
	Private oGridDet

	//Geração dos NCC's, conforme as parcelas U57
	U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	U57->(DbSeek( U56->U56_FILIAL+U56->U56_PREFIX+U56->U56_CODIGO ))
	While U57->(!EOF()) .and. U57->U57_FILIAL+U57->U57_PREFIX+U57->U57_CODIGO == U56->U56_FILIAL+U56->U56_PREFIX+U56->U56_CODIGO

		nPosAux := 0
		aColsEx := {}

		cQry := " SELECT E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_VALOR, E1_SALDO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_EMISSAO, R_E_C_N_O_ RECSE1 "
		cQry += " FROM "+RetSqlName("SE1")+" SE1 "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += "   AND E1_CLIENTE = '"+U56->U56_CODCLI+"' "
		cQry += "   AND E1_LOJA = '"+U56->U56_LOJA+"' "
		cQry += "   AND E1_TIPO IN ('RA','NCC') "
		cQry += "   AND E1_XCODBAR = ' ' "
		cQry += "   AND E1_SALDO > 0 " //com saldo a baixar
		cQry += " ORDER BY E1_EMISSAO, E1_PREFIXO, E1_NUM, E1_PARCELA"

		If Select("QAUX") > 0
			QAUX->(dbCloseArea())
		EndIf
		cQry := ChangeQuery(cQry)
		//dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry), "QAUX", .F., .T.)
		TcQuery cQry NEW Alias "QAUX"
		DbSelectArea("QAUX")
		QAUX->(DbGoTop())

		While QAUX->(!Eof())

			aadd(aColsEx, {"LBNO", QAUX->E1_PREFIXO, QAUX->E1_NUM, QAUX->E1_PARCELA, QAUX->E1_TIPO, QAUX->E1_VALOR, QAUX->E1_SALDO, QAUX->E1_CLIENTE, QAUX->E1_LOJA, QAUX->E1_NOMCLI, STOD(QAUX->E1_EMISSAO), QAUX->RECSE1, .F.})

			QAUX->(DbSkip())
		enddo

		QAUX->(DbCloseArea())

		if oDlgVinc == Nil

			DEFINE MSDIALOG oDlgVinc TITLE "Vincular Titulo Crédito" STYLE DS_MODALFRAME FROM 000, 000  TO 500, 800 COLORS 0, 16777215 PIXEL

			@ 005, 005 SAY "Selecione o titulo de crédito para vincular a esta requisição. O valor do titulo de crédito deve ser igual ao valor da parcela da requisição." SIZE 380, 007 OF oDlgVinc COLORS 0, 16777215 PIXEL

			@ 020, 005 SAY oSay1 PROMPT "Num. Requisição" SIZE 80, 007 OF oDlgVinc COLORS 0, 16777215 PIXEL
			@ 027, 005 MSGET oGet1 VAR (U57->U57_PREFIX+U57->U57_CODIGO) SIZE 080, 013 OF oDlgVinc COLORS 0, 16777215 PIXEL HASBUTTON WHEN .F.

			@ 020, 090 SAY oSay2 PROMPT "Parcela" SIZE 80, 007 OF oDlgVinc COLORS 0, 16777215 PIXEL
			@ 027, 090 MSGET oGet2 VAR (U57->U57_PARCEL) SIZE 040, 013 OF oDlgVinc COLORS 0, 16777215 PIXEL HASBUTTON WHEN .F.

			@ 020, 135 SAY oSay3 PROMPT "Valor" SIZE 80, 007 OF oDlgVinc COLORS 0, 16777215 PIXEL
			@ 027, 135 MSGET oGet3 VAR U57->U57_VALOR Picture "@E 999,999,999.99" SIZE 070, 013 OF oDlgVinc COLORS 0, 16777215 PIXEL HASBUTTON WHEN .F.

			@ 020, 210 SAY oSay4 PROMPT "Tipo Uso" SIZE 80, 007 OF oDlgVinc COLORS 0, 16777215 PIXEL
			@ 027, 210 MSGET oGet4 VAR (iif(U57->U57_TUSO == "S","Saque","Consumo")) SIZE 070, 013 OF oDlgVinc COLORS 0, 16777215 PIXEL HASBUTTON WHEN .F.

			aHeaderEx := MontaHeader(aCamposDet)
			oGridDet := MsNewGetDados():New( 050, 005, 219, 396, ,"AllwaysTrue","AllwaysTrue","+Field1+Field2",aAlterFields,,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgVinc, aHeaderEx, aColsEx)
			oGridDet:oBrowse:bLDblClick := {|| aEval(oGridDet:aCols, {|x| x[1]:="LBNO"}), oGridDet:aCols[oGridDet:nAt][1]:="LBOK" , oGridDet:oBrowse:Refresh() }

			@ 230, 355 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 015 OF oDlgVinc PIXEL Action iif(VldTela(), (nOpcx:=1, oDlgVinc:End()),)
			@ 230, 313 BUTTON oButton2 PROMPT "Cancelar" SIZE 037, 015 OF oDlgVinc PIXEL Action oDlgVinc:End()

			ACTIVATE MSDIALOG oDlgVinc CENTERED

			if nOpcx == 1
				nPosAux := aScan(oGridDet:aCols, {|x| x[1] == "LBOK"})
				aadd(aTitGrv, {oGridDet:aCols[nPosAux][len(oGridDet:aHeader)+1], U57->(Recno())} )
			else
				lOK := .F.
				EXIT
			endif
		else

			oGridDet:aCols := aColsEx

			ACTIVATE MSDIALOG oDlgVinc CENTERED
		endif

		U57->(DbSkip())
	EndDo

	if lOK
		for nX := 1 to len(aTitGrv)
			SE1->(DbGoTo(aTitGrv[nX][1]))
			U57->(DbGoTo(aTitGrv[nX][2]))
			RecLock("SE1",.F.)
				SE1->E1_XPLACA := U57->U57_PLACA
				SE1->E1_XCODBAR := AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL) //codigo de barras da requisição == chave do registro U57
			SE1->(MsUnlock())
		next nX

		//Altera o status da requisição para Liberado
		dbselectarea("U56")
		RecLock("U56")
			U56->U56_STATUS := "L"
		U56->(msunlock())
		MsgInfo("Liberação Efetuada com Sucesso, com titulo crédito vinculado!","Atenção")
	endif

Return

//---------------------------------------------------------------------
// Valida confirmar vincular tela
//---------------------------------------------------------------------
Static Function VldTela()

	Local lRet := .T.
	Local nPosAux := aScan(oGridDet:aCols, {|x| x[1] == "LBOK"})

	if nPosAux == 0 .OR. empty(oGridDet:aCols[nPosAux][3])
		MsgAlert("Selecione um titulo para vincular a requisição!","Atenção")
		lRet := .F.
	elseif oGridDet:aCols[nPosAux][7] <> U57->U57_VALOR
		MsgAlert("Saldo do titulo selecionado não bate com o valor de "+Alltrim(Transform(U57->U57_VALOR,"@E 999,999,999.99"))+" da parcela da requisição!","Atenção")
		lRet := .F.
	endif

Return lRet

/*/{Protheus.doc} TRETA32P
Definição do Prefixo
@author thebr
@since 29/04/2019
@version 1.0
@return cPrefixo
@type function
/*/
User Function TRETA32P()

	Local cPrefixo := " "
	Local lSrvPDV  := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV

	If !lSrvPDV
		cPrefixo := "R"+cFilAnt
	Else
		cPrefixo := "P"+cFilAnt
	EndIf

Return(cPrefixo)

/*/{Protheus.doc} TRETA32B
Gera parcelas "iguais" conforme preenchimento dos dados do cabeçalho
-> condição: quando não existir nenhum item preenchido ainda.

@author thebr
@since 02/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETA32B()

	Local oModel     := FWModelActive()
	Local oView 	 := FWViewActive()
	Local oModelU56  := oModel:GetModel( 'U56MASTER' )
	Local oModelU57  := oModel:GetModel( 'U57DETAIL' )
	Local nI         := 0
	Local nLinha 	 := oModelU57:Length()
	Local nQtd       := 0
	Local nValor     := 0
	Local cParc      := PADL("1",TAMSX3("U57_PARCEL")[1],"0")

	nQtd   := oModelU56:GetValue( 'U56_NPARC' )
	nValor := oModelU56:GetValue( 'U56_TOTAL' )
	nTipo  := oModelU56:GetValue( 'U56_TIPO' )

	if nQtd > 0 .and. (nValor > 0 .or. nTipo == "2") .and. nLinha <= 1

		oModelU57:GoLine( nLinha )
		nVlParc := nValor/nQtd

		if empty(oModelU57:GetValue( 'U57_PARCEL' )) .and. empty(oModelU57:GetValue( 'U57_VALOR' ))
			oModelU57:SetValue( 'U57_PARCEL'   , cParc )
			oModelU57:SetValue( 'U57_VALOR' , nVlParc )
			cParc := soma1( alltrim(cParc) )
			nQtd--
		endif

		for nI:=1 to nQtd
			if oModelU57:AddLine() == nLinha
				oModelU57:GoLine( nLinha )
				oModelU57:SetValue( 'U57_PARCEL'   , cParc )
				oModelU57:SetValue( 'U57_VALOR' , nVlParc )
				cParc  := soma1( alltrim(cParc) )
			else
				Help( ,, 'HELP',, 'Nao incluiu linha no grid U57' + CRLF + oModel:getErrorMessage()[6], 1, 0)
				nLinha 	 := oModelU57:Length()
			endif
			nLinha++
		next nI

		oModelU57:GoLine( 1 )
		oView:Refresh()

	endif

Return .T.

//--------------------------------------------------------------------------------------
// Monta aHeader de acordo com campos passados
//--------------------------------------------------------------------------------------
Static Function MontaHeader(aCampos, lRecno)

	Local aAuxLeg := {}
	Local aHeadRet := {}
	Local nX := 0
	Default lRecno := .F.

	For nX := 1 to Len(aCampos)
		If SubStr(aCampos[nX],1,3) == "LEG"
			aAuxLeg := StrToKArr(aCampos[nX],"-")
			if len(aAuxLeg) = 1
				aadd(aAuxLeg, ' ')
			endif
			Aadd(aHeadRet,{aAuxLeg[2],aAuxLeg[1],'@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
		elseif aCampos[nX] == "MARK"
			Aadd(aHeadRet,{" ","MARK",'@BMP',3,0,'','€€€€€€€€€€€€€€','C','','','',''})
		elseif !empty(GetSx3Cache(aCampos[nX], "X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aCampos[nX]) )
		EndIf
	Next nX

	if lRecno
		Aadd(aHeadRet, {"RecNo", "RECNO", "9999999999", 10, 0, "", "€€€€€€€€€€€€€€", "N", "","V", "", ""})
	endif

Return aHeadRet


//Varre o cliente padrão de todas filiais do grupo cEmpAnt, e verifica se o cliente informado é padrão
Static Function IsCliPad(cCliente, cLoja)

	Local lRet := .F.
	Local aArea		:= GetArea()						// Salva posicionamento atual
	Local cCliPad	:= "" //SuperGetMV("MV_CLIPAD")			// Cliente padrao
	Local cLojaPad	:= "" //SuperGetMV("MV_LOJAPAD")		// Loja do cliente padrao
	Local aFilPesq   := FWLoadSM0()
	Local nX
	Local bGetMvFil := {|cPar,cFil| SuperGetMV(cPar,,,cFil) }

	For nX := 1 To Len(aFilPesq) //varre o cliente padrão de todas filiais do grupo

		If cEmpAnt == aFilPesq[nX][1]

			cCliPad	 := Eval(bGetMvFil, "MV_CLIPAD", aFilPesq[nX][2]) // Cliente padrao
			cLojaPad := Eval(bGetMvFil, "MV_LOJAPAD", aFilPesq[nX][2]) // Loja do cliente padrao

			if cCliente+cLoja == cCliPad+cLojaPad
				lRet := .T.
				EXIT
			endif

		EndIf

	Next nX

	RestArea(aArea)

Return lRet

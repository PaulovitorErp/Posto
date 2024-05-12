#INCLUDE 'totvs.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} TRETA020
Cadastro de CRC

@author Wellington Gonçalves
@since 11/12/2015
@version 1.0
@return Nulo
@type function
/*/
User Function TRETA020()

	Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'ZE3' )
	oBrowse:SetDescription( 'Cadastro de CRC' )

// adiciona legenda no Browser
	oBrowse:AddLegend( "ZE3_STATUS == '1'"							, "GREEN"	, "Iniciado")
	oBrowse:AddLegend( "ZE3_STATUS == '2' .AND. EMPTY(ZE3_NOTA)"	, "YELLOW"  , "Aprovado")
	oBrowse:AddLegend( "!EMPTY(ZE3_NOTA)"							, "RED"		, "Finalizado")
	oBrowse:AddLegend( "ZE3_STATUS == '4'" 							, "BLACK"  	, "Cancelado")

	oBrowse:Activate()

Return NIL

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
description
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisar'   				Action 'PesqBrw'          					OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  				Action 'VIEWDEF.TRETA020' 					OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     				Action 'VIEWDEF.TRETA020' 					OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     				Action 'VIEWDEF.TRETA020' 					OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Aprovar'    				Action 'U_AprovCRC(ZE3->ZE3_NUMERO)'		OPERATION 06 ACCESS 0
	ADD OPTION aRotina Title 'Legenda'     				Action 'U_TA020LEG()' 						OPERATION 10 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
description
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

	Local oStruZE3 := FWFormStruct( 1, 'ZE3', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oStruZE4 := FWFormStruct( 1, 'ZE4', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oStruSC7 := FWFormStruct( 1, 'SC7', {|cCampo| VerCpAdd(1,'SC7', cCampo) }/*bAvalCampo*/, /*lViewUsado*/ ) //DefStrModel('SC7')
	Local oStruZE5 := FWFormStruct( 1, 'ZE5', {|cCampo| VerCpAdd(1,'ZE5', cCampo) }/*bAvalCampo*/, /*lViewUsado*/ ) //DefStrModel('ZE5')
	Local oModel, bRelac

	//adiciono campo legenda
	bRelac := {|A,B,C| FWINITCPO(A,B,C),XRET:=(iif(U_VerifAmo(SC7->C7_NUM,SC7->C7_ITEM) == "3" , "BR_VERDE" , "BR_VERMELHO" )),FWCLOSECPO(A,B,C,.T.),FWSETVARMEM(A,B,XRET),XRET }
	oStruSC7:AddField('','','STATUS','C',11,0,,,{},.F.,bRelac,,,.T.)

// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM020', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'ZE3MASTER', /*cOwner*/, oStruZE3 )

// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "ZE3_FILIAL" , "ZE3_NUMERO" })

// grid do pedido de compra
	oModel:AddGrid( 'SC7DETAIL', 'ZE3MASTER', oStruSC7, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

// Faz relaciomaneto do pedido de compras com o cabeçalho do CRC
	oModel:SetRelation( 'SC7DETAIL', { { 'C7_FILIAL', 'xFilial( "SC7" )' }, { 'C7_NUM', 'ZE3_PEDIDO' } }, SC7->( IndexKey( 1 ) ) )

	oModel:GetModel('SC7DETAIL'):SetOnlyQuery(.T.)
	oModel:GetModel('SC7DETAIL'):SetOnlyView(.T.)

// grid do pedido de compra
	oModel:AddGrid( 'ZE5DETAIL', 'SC7DETAIL', oStruZE5, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

// Faz relaciomaneto do pedido de compras com o cabeçalho do CRC
	oModel:SetRelation( 'ZE5DETAIL', { { 'ZE5_FILIAL', 'xFilial( "ZE5" )' }, { 'ZE5_PEDIDO', 'ZE3_PEDIDO' } , { 'ZE5_ITEMPE', 'C7_ITEM' } , { 'ZE5_PRODUT', 'C7_PRODUTO' } }, ZE5->( IndexKey( 1 ) ) )

	oModel:GetModel('ZE5DETAIL'):SetOnlyQuery(.T.)
	oModel:GetModel('ZE5DETAIL'):SetOnlyView(.T.)
	oModel:GetModel('ZE5DETAIL'):SetOptional(.T.)

// linha adicionada por orientacao do Wellington - G.SAMPAIO 28/10/2016
//oModel:GetModel('ZE5DETAIL'):SetNoInsertLine(.F.)

// grid dos itens do CRC
	oModel:AddGrid( 'ZE4DETAIL', 'SC7DETAIL', oStruZE4, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

// Faz relaciomaneto entre os compomentes do model
	oModel:SetRelation( 'ZE4DETAIL', { { 'ZE4_FILIAL', 'xFilial( "ZE4" )' }, { 'ZE4_NUMERO', 'ZE3_NUMERO' } , { 'ZE4_PEDIDO', 'ZE3_PEDIDO' } , { 'ZE4_ITEMPE', 'C7_ITEM' } , { 'ZE4_SEQ', 'C7_SEQUEN' } , { 'ZE4_PRODUT', 'C7_PRODUTO' }}, ZE4->( IndexKey( 3 ) ) )

// Indica que é opcional ter dados informados na Grid
	oModel:GetModel( 'ZE4DETAIL' ):SetOptional(.T.)

// valida a inclusão de linhas duplicadas
	oModel:GetModel( 'ZE4DETAIL' ):SetUniqueLine( {'ZE4_TQ','ZE4_DTLANC'} )

// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Cadastro de CRC' )

// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'ZE3MASTER' ):SetDescription( 'Dados do CRC' )
	oModel:GetModel( 'SC7DETAIL' ):SetDescription( 'Itens do Pedido'  )
	oModel:GetModel( 'ZE5DETAIL' ):SetDescription( 'Amostras'  )
	oModel:GetModel( 'ZE4DETAIL' ):SetDescription( 'Itens do CRC'  )

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
description
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function ViewDef()

	Local oStruZE3 	:= FWFormStruct( 2, 'ZE3' )
	Local oStruZE4 	:= FWFormStruct( 2, 'ZE4' )
	Local oStruSC7  := FWFormStruct( 2, 'SC7', {|cCampo| VerCpAdd(2,'SC7', cCampo) }/*bAvalCampo*/, /*lViewUsado*/ ) //DefStrView('SC7')
	Local oStruZE5  := FWFormStruct( 2, 'ZE5', {|cCampo| VerCpAdd(2,'ZE5', cCampo) }/*bAvalCampo*/, /*lViewUsado*/ ) //DefStrView('ZE5')
	Local oModel	:= FWLoadModel( 'TRETA020' )
	Local oView

	oStruSC7:AddField('STATUS',"01",'','',NIL,'GET','@BMP',,'',.F.,'','',{},1,'BR_VERMELHO',.T.)

// Cria o objeto de View
	oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_ZE3', oStruZE3, 'ZE3MASTER' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
	oView:AddGrid(  'VIEW_SC7', oStruSC7, 'SC7DETAIL' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
	oView:AddGrid(  'VIEW_ZE5', oStruZE5, 'ZE5DETAIL' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
	oView:AddGrid(  'VIEW_ZE4', oStruZE4, 'ZE4DETAIL' )

// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR'	, 30 )
	oView:CreateHorizontalBox( 'MEIO'		, 34 )
	oView:CreateHorizontalBox( 'SEPARADOR1'	, 02 )
	oView:CreateHorizontalBox( 'INFERIOR'	, 34 )

	oView:CreateVerticalBox( 'ESQUERDA'		, 49 , 'MEIO' )
	oView:CreateVerticalBox( 'SEPARADOR2'	, 02 , 'MEIO' )
	oView:CreateVerticalBox( 'DIREITA'		, 49 , 'MEIO' )

// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_ZE3', 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_SC7', 'ESQUERDA' )
	oView:SetOwnerView( 'VIEW_ZE5', 'DIREITA' )
	oView:SetOwnerView( 'VIEW_ZE4', 'INFERIOR' )

// Liga a identificacao do componente
	oView:EnableTitleView('VIEW_ZE3','Dados do CRC')
	oView:EnableTitleView('VIEW_SC7','Itens do Pedido')
	oView:EnableTitleView('VIEW_ZE5','Amostras')
	oView:EnableTitleView('VIEW_ZE4','Itens do CRC')

// Define fechamento da tela
	oView:SetCloseOnOk( {||.T.} )

// Define campos que terao Auto Incremento
	oView:AddIncrementField( 'VIEW_ZE4', 'ZE4_ITEM' )

// Define que o grid é somente visualização na view tbm
	oView:SetViewProperty('ZE5DETAIL', "ONLYVIEW")

	if INCLUI .OR. ALTERA
		oView:AddUserButton( 'Incluir Amostra', 'Amostra', {|| IncAmostra() } )
		oView:AddUserButton( 'Alterar Amostra', 'Amostra', {|| AltAmostra() } )
	endif
	oView:AddUserButton( 'Visualizar Amostra', 'Amostra', {|| VerAmostra() } )

Return oView

//Funcao para definir campos a utilziar nos models e views
Static Function VerCpAdd(nOpc, _cAlias, cCampo)

	Local lRet := .F.
	Local aCampos := {}
	
	if _cAlias == "SC7"
		if nOpc == 1
			aCampos := {"C7_FILIAL","C7_NUM","C7_ITEM","C7_SEQUEN","C7_PRODUTO","C7_DESCRI","C7_UM","C7_QUANT"}
		else
			aCampos := {"C7_ITEM","C7_PRODUTO","C7_DESCRI","C7_UM","C7_QUANT"}
		endif
	elseif _cAlias == "ZE5"
		if nOpc == 1
			aCampos := {"ZE5_FILIAL","ZE5_PEDIDO","ZE5_ITEMPE","ZE5_PRODUT","ZE5_LACRAM","ZE5_ASPECT","ZE5_COR","ZE5_DENSID","ZE5_MASSA","ZE5_TEOR","ZE5_TEORE","ZE5_ANALIS","ZE5_DATA","ZE5_APROV"}
		else
			aCampos := {"ZE5_LACRAM","ZE5_ASPECT","ZE5_COR","ZE5_DENSID","ZE5_MASSA","ZE5_TEOR","ZE5_TEORE","ZE5_ANALIS","ZE5_DATA","ZE5_APROV"}
		endif
	else
		lRet := .T.
	endif

	if !Empty(aCampos)
		lRet := aScan(aCampos, {|x| x == AllTrim(cCampo) })
	endif

Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} TA020LEG
Função que mostra a legenda dos CRC's
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function TA020LEG()

	BrwLegenda("Status do CRC","Legenda",{ {"BR_VERDE","Iniciado"},{"BR_AMARELO","Aprovado"},{"BR_VERMELHO","Finalizado"},{"BR_PRETO","Cancelado"} })

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} DefStrModel
Função cria a estrutura do alias SC7 para o model
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function DefStrModel(cAlias)

	Local aArea    		:= GetArea()
	Local bValid   		:= { || }
	Local bWhen    		:= { || }
	Local bRelac   		:= { || }
	Local aAux     		:= {}
	Local aCampos		:= {}
	Local oStruct 		:= FWFormModelStruct():New()
	Local nX			:= 1

	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local cAliasSX2 := GetNextAlias() // apelido para o arquivo de trabalho
	Local cAliasSX7 := GetNextAlias() // apelido para o arquivo de trabalho
	Local cAliasSIX := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	If cAlias == "SC7"
		aCampos := {"C7_FILIAL","C7_NUM","C7_ITEM","C7_SEQUEN","C7_PRODUTO","C7_DESCRI","C7_UM","C7_QUANT"}
	Else
		aCampos := {"ZE5_FILIAL","ZE5_PEDIDO","ZE5_ITEMPE","ZE5_PRODUT","ZE5_LACRAM","ZE5_ASPECT","ZE5_COR","ZE5_DENSID","ZE5_MASSA","ZE5_TEOR","ZE5_TEORE","ZE5_ANALIS","ZE5_DATA","ZE5_APROV"}
	EndIf

//-------------------------------------------------------------------
// Tabela
//-------------------------------------------------------------------
// abre o dicionário SX2
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX2, "SX2", NIL, .F.)
	lOpen := Select(cAliasSX2) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX2)
	(cAliasSX2)->( DbSetOrder( 1 ) ) //X2_CHAVE
	(cAliasSX2)->( DbGoTop() )

	(cAliasSX2)->(DbSeek(cAlias))

	oStruct:AddTable((cAliasSX2)->&("X2_CHAVE"),StrTokArr((cAliasSX2)->&("X2_UNICO"), '+') ,(cAliasSX2)->&("X2_NOME"))

//-------------------------------------------------------------------
// Indices
//-------------------------------------------------------------------
// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSIX, "SIX", NIL, .F.)
	lOpen := Select(cAliasSIX) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSIX)
	(cAliasSIX)->( DbSetOrder( 1 ) ) //INDICE+ORDEM
	(cAliasSIX)->( DbGoTop() )

	(cAliasSIX)->(DbSeek(cAlias))

	nOrdem := 0

	While (cAliasSIX)->(!EOF()) .AND. (cAliasSIX)->&("INDICE") == cAlias
		oStruct:AddIndex(nOrdem++,(cAliasSIX)->&("ORDEM"),(cAliasSIX)->&("CHAVE"),SIXDescricao(),(cAliasSIX)->&("F3"),(cAliasSIX)->&("NICKNAME") ,((cAliasSIX)->&("SHOWPESQ") <> 'N'))
		(cAliasSIX)->(DbSkip())
	EndDo

//-------------------------------------------------------------------
// Campos
//-------------------------------------------------------------------   
// crio uma coluna com o status da amostra do pedido
// oStruct:AddField('','','STATUS','C',11,0,,,{},.F.,{|A,B,C| FWINITCPO(A,B,C),XRET:=(iif(Posicione("ZE5",1,xFilial("ZE5") + SC7->C7_NUM + SC7->C7_ITEM,"ZE5_APROV") == "S" , "BR_VERDE" , "BR_VERMELHO" )),FWCLOSECPO(A,B,C,.T.),FWSETVARMEM(A,B,XRET),XRET }/*{|| iif(Posicione("ZE5",1,xFilial("ZE5") + SC7->C7_NUM + SC7->C7_ITEM,"ZE5_APROV") == "S" , "BR_VERDE" , "BR_VERMELHO" )}*/,,,.T.)

	If cAlias == "SC7"
		bRelac := {|A,B,C| FWINITCPO(A,B,C),XRET:=(iif(U_VerifAmo(SC7->C7_NUM,SC7->C7_ITEM) == "3" , "BR_VERDE" , "BR_VERMELHO" )),FWCLOSECPO(A,B,C,.T.),FWSETVARMEM(A,B,XRET),XRET }
		oStruct:AddField('','','STATUS','C',11,0,,,{},.F.,bRelac,,,.T.)
	EndIf

// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)
	lOpen := Select(cAliasSX3) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 2 ) ) //X3_CAMPO
	(cAliasSX3)->( DbGoTop() )

	For nX := 1 To Len(aCampos)

		If (cAliasSX3)->(DbSeek(aCampos[nX]))

			bValid 	:= FwBuildFeature( 1, (cAliasSX3)->&("X3_VALID")   )
			bWhen  	:= FwBuildFeature( 2, (cAliasSX3)->&("X3_WHEN") )
			bRelac 	:= FwBuildFeature( 3, (cAliasSX3)->&("X3_RELACAO") )
			aBox	:= StrTokArr(AllTrim(X3CBox()),';')

			oStruct:AddField( 			;
				AllTrim(X3Titulo()), 		;	// [01] Titulo do campo
			AllTrim(X3Descric()), 		;	// [02] ToolTip do campo
			AllTrim((cAliasSX3)->&("X3_CAMPO")), 	;	// [03] Id do Field
			(cAliasSX3)->&("X3_TIPO"), 				;	// [04] Tipo do campo
			(cAliasSX3)->&("X3_TAMANHO"), 			;	// [05] Tamanho do campo
			(cAliasSX3)->&("X3_DECIMAL"), 			;	// [06] Decimal do campo
			bValid, 					;	// [07] Code-block de valida?o do campo
			bWhen, 						;	// [08] Code-block de valida?o When do campo
			aBox, 						;	// [09] Lista de valores permitido do campo
			.F., 						;	// [10] Indica se o campo tem preenchimento obrigat?io
			bRelac, 					;	// [11] Code-block de inicializacao do campo
			NIL, 						;	// [12] Indica se trata-se de um campo chave
			NIL, 						;	// [13] Indica se o campo pode receber valor em uma opera?o de update.
			((cAliasSX3)->&("X3_CONTEXT") == 'V')) 		// [14] Indica se o campo ?virtual

		EndIf

	Next nX

//-------------------------------------------------------------------
// Gatilhos
//-------------------------------------------------------------------
// abre o dicionário SX7
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX7, "SX7", NIL, .F.)
	lOpen := Select(cAliasSX7) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX7)
	(cAliasSX7)->( DbSetOrder( 1 ) ) //X7_CAMPO+X7_SEQUENC
	(cAliasSX7)->( DbGoTop() )

	For nX := 1 To Len(aCampos)
		If (cAliasSX7)->(DbSeek(aCampos[nX]))
			aAux :=	FwStruTrigger((cAliasSX7)->&("X7_CAMPO"),(cAliasSX7)->&("X7_CDOMIN"),(cAliasSX7)->&("X7_REGRA"),(cAliasSX7)->&("X7_SEEK")=='S',(cAliasSX7)->&("X7_ALIAS"),(cAliasSX7)->&("X7_ORDEM"),(cAliasSX7)->&("X7_CHAVE"),(cAliasSX7)->&("X7_CONDIC"),(cAliasSX7)->&("X7_SEQUENC"))
			oStruct:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
		EndIf
	Next nX

	RestArea( aArea )

Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} DefStrView
Função cria a estrutura do alias SC7 para a View
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function DefStrView(cAlias)

	Local aArea     	:= GetArea()
	Local aCampos		:= {}
	Local oStruct   	:= FWFormViewStruct():New()
	Local aCombo    	:= {}
	Local nInitCBox 	:= 0
	Local nMaxLenCb 	:= 0
	Local aAux      	:= {}
	Local nI        	:= 1
	Local nX			:= 1
	Local cGSC      	:= ''

	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local cAliasSXA:= GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)
	lOpen := Select(cAliasSX3) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 2 ) ) //X3_CAMPO
	(cAliasSX3)->( DbGoTop() )

	If cAlias == "SC7"
		aCampos := {"C7_ITEM","C7_PRODUTO","C7_DESCRI","C7_UM","C7_QUANT"}
	Else
		aCampos := {"ZE5_LACRAM","ZE5_ASPECT","ZE5_COR","ZE5_DENSID","ZE5_MASSA","ZE5_TEOR","ZE5_TEORE","ZE5_ANALIS","ZE5_DATA","ZE5_APROV"}
	EndIf

//-------------------------------------------------------------------
// Campos
//-------------------------------------------------------------------      

	If cAlias == "SC7"
		oStruct:AddField('STATUS',"01",'','',NIL,'GET','@BMP',,'',.F.,'','',{},1,'BR_VERMELHO',.T.)
	EndIf

	For nX := 1 To Len(aCampos)

		If (cAliasSX3)->(DbSeek(aCampos[nX]))

			aCombo := {}

			If !Empty(X3Cbox())

				nInitCBox := 0
				nMaxLenCb := 0

				aAux := RetSX3Box( X3Cbox() , @nInitCBox, @nMaxLenCb, (cAliasSX3)->&("X3_TAMANHO") )

				For nI := 1 To Len(aAux)
					aAdd( aCombo, aAux[nI][1] )
				Next nI

			EndIf

			bPictVar := FwBuildFeature( 4, (cAliasSX3)->&("X3_PICTVAR") )
			cGSC     := IIf( Empty( X3Cbox() ) , IIf( (cAliasSX3)->&("X3_TIPO") == 'L', 'CHECK', 'GET' ) , 'COMBO' )

			oStruct:AddField( 			;
				AllTrim((cAliasSX3)->&("X3_CAMPO")), 	;	// [01] Campo
			(cAliasSX3)->&("X3_ORDEM") ,				;	// [02] Ordem
			AllTrim(X3Titulo()), 		;	// [03] Titulo
			AllTrim(X3Descric()), 		;	// [04] Descricao
			NIL, 						;	// [05] Help
			cGSC, 						;	// [06] Tipo do campo   COMBO, Get ou CHECK
			(cAliasSX3)->&("X3_PICTURE"), 			;	// [07] Picture
			bPictVar, 					;	// [08] PictVar
			(cAliasSX3)->&("X3_F3"), 				;	// [09] F3
			(cAliasSX3)->&("X3_VISUAL") <> 'V', 		;	// [10] Editavel
			(cAliasSX3)->&("X3_FOLDER"), 			;	// [11] Folder
			(cAliasSX3)->&("X3_FOLDER"), 			;	// [12] Group
			aCombo,						;	// [13] Lista Combo
			nMaxLenCb, 					;	// [14] Tam Max Combo
			(cAliasSX3)->&("X3_INIBRW"), 			;	// [15] Inic. Browse
			((cAliasSX3)->&("X3_CONTEXT") == 'V'))   	// [16] Virtual

		EndIf

		(cAliasSX3)->(DbSkip())

	Next nX

//-------------------------------------------------------------------
// Folders
//-------------------------------------------------------------------
// abre o dicionário SXA
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSXA, "SXA", NIL, .F.)
	lOpen := Select(cAliasSXA) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSXA)
	(cAliasSXA)->( DbSetOrder( 1 ) ) //XA_ALIAS+XA_ORDEM
	(cAliasSXA)->( DbGoTop() )

	(cAliasSXA)->( dbSeek( cAlias ) )

	While ! (cAliasSXA)->( EOF() ) .AND. (cAliasSXA)->&("XA_ALIAS") == cAlias
		oStruct:AddFolder((cAliasSXA)->&("XA_ORDEM"),(cAliasSXA)->&("XA_DESCRIC"))
		(cAliasSXA)->(DbSkip())
	EndDo

	RestArea(aArea)

Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} ValSC7
Função que valida o pedido de compras
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function ValSC7()

	Local lRet 		:= .F.
	Local aAreaSC7	:= SC7->(GetArea())
	Local aAreaZE5	:= ZE5->(GetArea())
	Local aAreaZE3	:= ZE3->(GetArea())
	Local aArea		:= GetArea()
	Local oModel	:= FWModelActive()
	Local oView		:= FWViewActive()
	Local oModelZE3 := oModel:GetModel('ZE3MASTER')
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')
	Local oModelZE4	:= oModel:GetModel('ZE4DETAIL')
//Local nLinha 	:= oModelSC7:Length()  

// verifico se o pedido de compras é válido
	SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
	If SC7->(DbSeek(xFilial("SC7") + oModelZE3:GetValue( 'ZE3_PEDIDO' )))

		// verifico se já existe um CRC cadastrado para este pedido de compras
		If Empty(SC7->C7_XCRC)

			// limpo o grid dos itens do pedido de compra
			U_ClearAcolsMVC(oModelSC7,oView)

			// limpo o grid dos itens do CRC
			U_ClearAcolsMVC(oModelZE4,oView)

			// atualizo o crid com os itens do pedido de compras
			RefreshSC7()

			lRet := .T.

		Else
			Help(,,'Help',,"Já existe o CRC " + AllTrim(ZE3->ZE3_NUMERO) + " cadastrado para este pedido de compras!",1,0)
		EndIf

	Else
		Help(,,'Help',,"Pedido de compras inválido!",1,0)
	EndIf

	RestArea(aAreaSC7)
	RestArea(aAreaZE5)
	RestArea(aAreaZE3)
	RestArea(aArea)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} UIniPedZE3
Função chamada na abertura da tela do CRC.
Caso a inclusão seja chamada da rotina de pedido de 
compras, virá com o campo do pedido preenchido.

@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function UIniPedZE3(oView)

	Local nOperation := oView:GetOperation()

// apenas se for inclusão
	If nOperation == 3

		If AllTrim(FunName()) == "MATA121"

			// preencho com o número do pedido de compras posicionado
			FwFldPut("ZE3_PEDIDO",SC7->C7_NUM,,,,.T.)

			// refresh na view
			oView:Refresh()

			// atualizo o crid com os itens do pedido de compras
			RefreshSC7()

		EndIf

	EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} ValTQZE4
Função que valida o tanque informado.
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function ValTQZE4()

	Local lRet 		:= .F.
	Local aArea		:= GetArea()
	Local aAreaZE0	:= ZE0->(GetArea())
	Local aAreaMHZ	:= MHZ->(GetArea())
	Local oModel	:= FWModelActive()
//Local oView		:= FWViewActive()
	Local oModelZE3 := oModel:GetModel('ZE3MASTER')
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')
	Local cRet		:= ""

// valido se o item do pedido de compra tem amostra aprovada
	cRet := U_VerifAmo(oModelZE3:GetValue( 'ZE3_PEDIDO' ),oModelSC7:GetValue( 'C7_ITEM' ))

	If cRet == "3" // se existir amostra aprovada para este item do pedido

		// posiciono no tanque
		ZE0->(DbSetOrder(1)) // ZE0_FILIAL + ZE0_TANQUE
		If ZE0->(DbSeek(xFilial("ZE0") + M->ZE4_TQ))

			MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN
			If MHZ->(DbSeek(xFilial("MHZ") + ZE0->ZE0_GRPTQ))
				if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dDataBase) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dDataBase))
					If AllTrim(MHZ->MHZ_CODPRO) == AllTrim(oModelSC7:GetValue('C7_PRODUTO'))
						lRet := .T.
					Else
						Help(,,'Help',,"O produto do tanque informado não corresponde ao produto do pedido de compras!",1,0)
					EndIf
				Else
					Help(,,'Help',,"O filtro informado no tanque está desativado!",1,0)
				EndIf
			Else
				Help(,,'Help',,"O filtro informado no tanque é inválido!",1,0)
			EndIf

		Else
			Help(,,'Help',,"Tanque inválido!",1,0)
		EndIf

	Else
		Help(,,'Help',,"Não existe amostra aprovada para este item do pedido de compras!",1,0)
	EndIf

	RestArea(aArea)
	RestArea(aAreaZE0)
	RestArea(aAreaMHZ)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} LOCTQZE4
Função que filtra o tanque de acordo com o produto da SC7.
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function LOCTQZE4()

	Local lRet 		:= .F.
//Local aArea		:= GetArea()
//Local aAreaMHZ	:= MHZ->(GetArea())
	Local oModel	:= FWModelActive()
//Local oView		:= FWViewActive()
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')

	MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN
	If MHZ->(DbSeek(xFilial("MHZ") + ZE0->ZE0_GRPTQ))
		if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dDataBase) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dDataBase))
			If AllTrim(MHZ->MHZ_CODPRO) == AllTrim(oModelSC7:GetValue('C7_PRODUTO'))
				lRet := .T.
			EndIf
		EndIf
	EndIf

// RestArea(aArea)
// RestArea(aAreaMHZ)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} ValMedZE4
Função que valida as medidas do tanque informado.
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function ValMedZE4()

	Local lRet 		:= .T.
	Local aArea		:= GetArea()
	Local aAreaSC7	:= SC7->(GetArea())
	Local aAreaZE7	:= ZE7->(GetArea())
	Local oModel	:= FWModelActive()
//Local oView		:= FWViewActive()  
//Local oModelSC7 := oModel:GetModel('SC7DETAIL')         
	Local oModelZE4 := oModel:GetModel('ZE4DETAIL')
	Local nCap1		:= 0
	Local nCap2		:= 0
	Local nDif		:= 0

	If Empty(oModelZE4:GetValue('ZE4_QRINI')) .OR. Empty(oModelZE4:GetValue('ZE4_QRFIM'))
		oModelZE4:SetValue('ZE4_DIFREG',nDif)
	Else

		// posiciono no tanque
		ZE0->(DbSetOrder(1)) // ZE0_FILIAL + ZE0_TANQUE
		If ZE0->(DbSeek(xFilial("ZE0") + oModelZE4:GetValue('ZE4_TQ')))

			ZE7->(DbSetOrder(1)) // ZE7_FILIAL + ZE7_CODIGO + STR(ZE7_MEDIDA)
			If ZE7->(DbSeek(xFilial("ZE7") + ZE0->ZE0_TABVOL + cValToChar(oModelZE4:GetValue('ZE4_QRINI'))))

				nCap1 := ZE7->ZE7_VOLUME

				ZE7->(DbGoTop())
				If ZE7->(DbSeek(xFilial("ZE7") + ZE0->ZE0_TABVOL + cValToChar(oModelZE4:GetValue('ZE4_QRFIM'))))

					nCap2 	:= ZE7->ZE7_VOLUME
					nDif	:= nCap2 - nCap1

					oModelZE4:SetValue('ZE4_DIFREG',nDif)

				Else

					oModelZE4:SetValue('ZE4_DIFREG',nDif)
					Help(,,'Help',,"A medida final informada não existe na tabela de capacidade de volumes!",1,0)
					lRet := .F.

				EndIf

			Else

				oModelZE4:SetValue('ZE4_DIFREG',nDif)
				Help(,,'Help',,"A medida inicial informada não existe na tabela de capacidade de volumes!",1,0)
				lRet := .F.

			EndIf

		Else
			Help(,,'Help',,"Tanque inválido!",1,0)
		EndIf

	EndIf

	RestArea(aArea)
	RestArea(aAreaSC7)
	RestArea(aAreaZE7)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} ValQtdZE4
Função que valida a quantidade informada.
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function ValQtdZE4()

	Local lRet 	   		:= .F.
	Local aArea	   		:= GetArea()
	Local oModel   		:= FWModelActive()
//Local oView	   		:= FWViewActive()
//Local oModelZE3	 	:= oModel:GetModel('ZE3MASTER')  
	Local oModelSC7 	:= oModel:GetModel('SC7DETAIL')
	Local oModelZE4 	:= oModel:GetModel('ZE4DETAIL')
	Local nX	   		:= 1
	Local nQtdCRC  		:= 0
	Local nQtdSC7  		:= oModelSC7:GetValue('C7_QUANT')
	Local aSaveLine 	:= FWSaveRows()
	Local cMsgErro		:= ""

	For nX := 1 To oModelZE4:Length()

		// posiciono na linha
		oModelZE4:Goline(nX)

		nQtdCRC += oModelZE4:GetValue('ZE4_QTDE')

	Next nX

// se a somatoria dos CRC's for menor ou igual a à quantidade do pedido
	If nQtdCRC <= nQtdSC7
		lRet := .T.
	Else
		cMsgErro := "A quantidade informada é superior a quantidade do pedido de compra!" + CRLF
		cMsgErro += "Quantidade do pedido: " + Alltrim(Transform(nQtdSC7,"@E 999,999,999.99")) + CRLF
		cMsgErro += "Quantidade informada no CRC: " + Alltrim(Transform(nQtdCRC,"@E 999,999,999.99")) + CRLF
		Help(,,'Help',,cMsgErro,1,0)
	EndIf

	RestArea(aArea)

// restauro o posicionamento das linhas dos grids
	FWRestRows(aSaveLine)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} IncAmostra
Função que chama a tela de inclusão	da amostra
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function IncAmostra()

	Local aArea		:= GetArea()
	Local aAreaSC7	:= SC7->(GetArea())
	Local aAreaZE5	:= ZE5->(GetArea())
	Local nInc 		:= 0
	Local oModel	:= FWModelActive()
	Local oView		:= FWViewActive()
	Local oModelZE3 := oModel:GetModel('ZE3MASTER')
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')
	Local oModelZE5	:= oModel:GetModel('ZE5DETAIL')
//Local nLinha 	:= oModelSC7:Length()           
	Local nX		:= 1
	Local nPosLacre	:= aScan(oModelZE5:aHeader,{|x| AllTrim(x[2]) == "ZE5_LACRAM"})

// posiciono na SC7 para que a tela de amostra já venha preenchida com os dados do pedido
	SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
	If SC7->(DbSeek(xFilial("SC7") + oModelZE3:GetValue( 'ZE3_PEDIDO' ) + oModelSC7:GetValue( 'C7_ITEM' )))

		nInc := FWExecView('INCLUIR','TRETA048',3,,{||.T.})

	EndIf

	If nInc == 0 // se o usuário confirmou a operação

		//oModelZE5:SetOnlyView(.F.)
		//TODO tratar pois está duplcando a linha na inclusão
		oModelZE5:SetNoInsertLine(.F.)

		ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
		If ZE5->(DbSeek(xFilial("ZE5") + oModelZE3:GetValue( 'ZE3_PEDIDO' ) + oModelSC7:GetValue( 'C7_ITEM' )))

			While ZE5->(!Eof()) .AND. ZE5->ZE5_FILIAL == xFilial("ZE5") .AND. ZE5->ZE5_PEDIDO == oModelZE3:GetValue( 'ZE3_PEDIDO' ) .AND. ZE5->ZE5_ITEMPE == oModelSC7:GetValue( 'C7_ITEM' )

				If aScan(oModelZE5:aCols,{|x| AllTrim(x[nPosLacre]) == AllTrim(ZE5->ZE5_LACRAM)}) == 0

					// se a primeira linha não estiver em branco, insiro uma nova linha
					If !Empty(oModelZE5:GetValue("ZE5_LACRAM"))
						oModelZE5:AddLine()
						oModelZE5:GoLine( oModelZE5:Length() )
					EndIf

					oModelZE5:LoadValue( "ZE5_LACRAM"   , ZE5->ZE5_LACRAM )
					oModelZE5:LoadValue( "ZE5_ASPECT"  	, ZE5->ZE5_ASPECT )
					oModelZE5:LoadValue( "ZE5_COR" 		, ZE5->ZE5_COR )
					oModelZE5:LoadValue( "ZE5_DENSID"  	, ZE5->ZE5_DENSID )
					oModelZE5:LoadValue( "ZE5_MASSA" 	, ZE5->ZE5_MASSA )
					oModelZE5:LoadValue( "ZE5_TEOR" 	, ZE5->ZE5_TEOR )
					oModelZE5:LoadValue( "ZE5_TEORE" 	, ZE5->ZE5_TEORE )
					oModelZE5:LoadValue( "ZE5_ANALIS" 	, ZE5->ZE5_ANALIS )
					oModelZE5:LoadValue( "ZE5_DATA" 	, ZE5->ZE5_DATA )
					oModelZE5:LoadValue( "ZE5_APROV" 	, ZE5->ZE5_APROV )

					nX++

				EndIf

				ZE5->(DbSkip())

			EndDo

		EndIf

		oModelZE5:SetNoInsertLine(.T.)
		//oModelZE5:SetOnlyView(.T.)

		oModelZE5:GoLine(1)
		oView:Refresh()

		// atualizo o grid dos itens do pedido
		RefreshSC7()

	EndIf

	RestArea(aAreaZE5)
	RestArea(aAreaSC7)
	RestArea(aArea)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} AltAmostra
Função que chama a tela de alteração da amostra
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function AltAmostra()

	Local nAlt 		:= 0
	Local oModel	:= FWModelActive()
//Local oView		:= FWViewActive()
	Local oModelZE3 := oModel:GetModel('ZE3MASTER')
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')
	Local oModelZE5	:= oModel:GetModel('ZE5DETAIL')
//Local nLinha 	:= oModelSC7:Length()           

	ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
	If ZE5->(DbSeek(xFilial("ZE5") + oModelZE3:GetValue( 'ZE3_PEDIDO' ) + oModelSC7:GetValue( 'C7_ITEM' ) + oModelZE5:GetValue( 'ZE5_LACRAM' )))

		// chamo função de alteração da amostra
		nAlt := FWExecView('ALTERAR','TRETA048',4,,{||.T.})

		// atualizo os campos da amostra
		If nAlt == 0

			oModelZE5:LoadValue( "ZE5_LACRAM"   , ZE5->ZE5_LACRAM )
			oModelZE5:LoadValue( "ZE5_ASPECT"  	, ZE5->ZE5_ASPECT )
			oModelZE5:LoadValue( "ZE5_COR" 		, ZE5->ZE5_COR )
			oModelZE5:LoadValue( "ZE5_DENSID"  	, ZE5->ZE5_DENSID )
			oModelZE5:LoadValue( "ZE5_MASSA" 	, ZE5->ZE5_MASSA )
			oModelZE5:LoadValue( "ZE5_TEOR" 	, ZE5->ZE5_TEOR )
			oModelZE5:LoadValue( "ZE5_TEORE" 	, ZE5->ZE5_TEORE )
			oModelZE5:LoadValue( "ZE5_ANALIS" 	, ZE5->ZE5_ANALIS )
			oModelZE5:LoadValue( "ZE5_DATA" 	, ZE5->ZE5_DATA )
			oModelZE5:LoadValue( "ZE5_APROV" 	, ZE5->ZE5_APROV )

			// atualizo o grid dos itens do pedido
			RefreshSC7()

		EndIf

	Else
		Help(,,'Help',,"Amostra não encontrada!",1,0)
	EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} VerAmostra
Função que chama a tela de alteração da amostra
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function VerAmostra()

	Local nAlt 		:= 0
	Local oModel	:= FWModelActive()
//Local oView		:= FWViewActive()
	Local oModelZE3 := oModel:GetModel('ZE3MASTER')
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')
	Local oModelZE5	:= oModel:GetModel('ZE5DETAIL')
//Local nLinha 	:= oModelSC7:Length()           

	ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
	If ZE5->(DbSeek(xFilial("ZE5") + oModelZE3:GetValue( 'ZE3_PEDIDO' ) + oModelSC7:GetValue( 'C7_ITEM' ) + oModelZE5:GetValue( 'ZE5_LACRAM' )))

		// chamo função de alteração da amostra
		nAlt := FWExecView('VISUALIZAR','TRETA048',1,,{||.T.})

	Else
		Help(,,'Help',,"Amostra não encontrada!",1,0)
	EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} RefreshSC7
Função que atualiza a legenda dos itens do pedido
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function RefreshSC7()

	Local oModel	:= FWModelActive()
//Local oView		:= FWViewActive()
	Local oModelZE3 := oModel:GetModel('ZE3MASTER')
	Local oModelSC7 := oModel:GetModel('SC7DETAIL')
//Local oModelZE5	:= oModel:GetModel('ZE5DETAIL')       
	Local nX		:= 1
	Local aSaveLine := FWSaveRows()
	Local cStatus	:= ""
	Local cRet		:= ""

	For nX := 1 To oModelSC7:Length()

		// posiciono na linha atual
		oModelSC7:Goline(nX)

		// verifico o status da amostra
		cRet := U_VerifAmo(oModelZE3:GetValue( 'ZE3_PEDIDO' ),oModelSC7:GetValue( 'C7_ITEM' ))

		If cRet == "3" // se existir amostra aprovada para este item do pedido
			cStatus := "BR_VERDE"
		Else
			cStatus := "BR_VERMELHO"
		EndIf

		oModelSC7:LoadValue("STATUS", cStatus)

	Next nX

// restauro o posicionamento das linhas dos grids
	FWRestRows(aSaveLine)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} AprovCRC
Função que faz a aprovação do CRC
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
User Function AprovCRC(cNumCRC)

	Local nX
	Local lAprova  		:= .F.
	Local aArea	   		:= GetArea()
	Local aAreaSC7 		:= SC7->(GetArea())
	Local aAreaZE4 		:= ZE4->(GetArea())
	Local aAreaZE0 		:= ZE0->(GetArea())
	Local aAreaMHZ 		:= MHZ->(GetArea())
	Local nItem	   		:= 1
	Local aItem			:= {}
	Local cFieldsAdd	:= SuperGetMv("TP_CPADCRC",,"") //Exemplo: C7_XTEST1/C7_XTEST2
	Local aFieldsAdd	:= {}
	Local aItens   		:= {}
	Local aCab			:= {}
	Local nRecnoSC7		:= 0
	Local lGerouPed		:= .F.
	Local aCRC			:= {}
	Local aItemAmostra	:= {}
	Local aAmostra 		:= {}
	DEFAULT lVlStat := .T.

	if !empty(cFieldsAdd)
		aFieldsAdd := StrToKArr(cFieldsAdd,"/")
	endif

// verifico se o CRC é válido
	ZE3->(DbSetOrder(1)) // ZE3_FILIAL + ZE3_NUMERO
	If ZE3->(DbSeek(xFilial("ZE3") + cNumCRC))

		if ZE3->ZE3_STATUS == '1'
			// percorro todos os itens do pedido de compras
			SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
			If SC7->(DbSeek(xFilial("SC7") + ZE3->ZE3_PEDIDO))

				// preencho o cabeçalho do pedido de compras
				aadd(aCab , {"C7_NUM"   	, SC7->C7_NUM      	, Nil})
				aadd(aCab , {"C7_EMISSAO"	, SC7->C7_EMISSAO	, Nil})
				aadd(aCab , {"C7_FORNECE"  	, SC7->C7_FORNECE	, Nil})
				aadd(aCab , {"C7_LOJA"  	, SC7->C7_LOJA		, Nil})
				aadd(aCab , {"C7_CONTATO" 	, SC7->C7_CONTATO	, Nil})
				aadd(aCab , {"C7_COND"    	, SC7->C7_COND		, Nil})
				aadd(aCab , {"C7_FILENT"  	, SC7->C7_FILENT	, Nil})

				While SC7->(!Eof()) .AND. SC7->C7_FILIAL == xFilial("SC7") .AND. SC7->C7_NUM == ZE3->ZE3_PEDIDO

					nQtdZE4 		:= 0
					nQtdSC7 		:= SC7->C7_QUANT
					aItemAmostra	:= {}

					ZE4->(DbSetOrder(3)) // ZE4_FILIAL + ZE4_NUMERO + ZE4_PEDIDO + ZE4_ITEMPE + ZE4_SEQ
					If ZE4->(DbSeek(xFilial("ZE4") + cNumCRC + SC7->C7_NUM + SC7->C7_ITEM + SC7->C7_SEQUEN))

						While ZE4->(!Eof())	.AND. ZE4->ZE4_FILIAL == xFilial("ZE4") .AND. ZE4->ZE4_NUMERO == cNumCRC ;
								.AND. ZE4->ZE4_PEDIDO == SC7->C7_NUM .AND. ZE4->ZE4_ITEMPE == SC7->C7_ITEM .AND. ZE4->ZE4_SEQ == SC7->C7_SEQUEN

							// se foi informada a data de lançamento do rateio
							If !Empty(ZE4->ZE4_DTLANC)

								// posiciono no tanque
								ZE0->(DbSetOrder(1)) // ZE0_FILIAL + ZE0_TANQUE
								If ZE0->(DbSeek(xFilial("ZE0") + ZE4->ZE4_TQ))

									// posiciono no filtro
									MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN
									If MHZ->(DbSeek(xFilial("MHZ") + ZE0->ZE0_GRPTQ))

										aItem 	:= {}
										aadd(aItem , {"C7_ITEM"   	, StrZero(nItem,4)	    , Nil})
										aadd(aItem , {"C7_PRODUTO"	, SC7->C7_PRODUTO		, Nil})
										aadd(aItem , {"C7_QUANT"  	, ZE4->ZE4_QTDE	        , Nil})
										aadd(aItem , {"C7_PRECO"  	, SC7->C7_PRECO		    , Nil})
										aadd(aItem , {"C7_CC" 	 	, SC7->C7_CC		    , Nil}) // centro de custo
										aadd(aItem , {"C7_DATPRF" 	, SC7->C7_DATPRF		, Nil}) // data de entrega
										aadd(aItem , {"C7_TES"    	, SC7->C7_TES			, Nil})
										aadd(aItem , {"C7_LOCAL"  	, MHZ->MHZ_LOCAL		, Nil})

										If !Empty(SC7->C7_NUMSC)
											aadd(aItem , {"C7_NUMSC" 	, SC7->C7_NUMSC 		, Nil})// adicionado por G.SAMPAIO - 15/09/2016
										EndIf

										If !Empty(SC7->C7_ITEMSC)
											aadd(aItem , {"C7_ITEMSC" 	, SC7->C7_ITEMSC 		, Nil})// adicionado por G.SAMPAIO - 15/09/2016
										EndIf

										aadd(aItem , {"C7_ICMSRET"  , SC7->C7_ICMSRET		, Nil})
										aadd(aItem , {"C7_VALSOL"  	, SC7->C7_VALSOL		, Nil})
										aadd(aItem , {"C7_BASESOL"  , SC7->C7_BASESOL		, Nil})

										aadd(aItem , {"C7_XCRC"  	, cNumCRC				, Nil})
										aadd(aItem , {"C7_XSTCRC"  	, '2'	 				, Nil})

										// adiciono a natureza - g.sampaio 07/12/2016
										If SC7->(Fieldpos("C7_NATUREZ")) > 0
											aadd(aItem , {"C7_NATUREZ"  , SC7->C7_NATUREZ		, Nil})
										EndIf

										for nX := 1 to len(aFieldsAdd)
											aadd(aItem , {aFieldsAdd[nX]  , SC7->&(aFieldsAdd[nX])	, Nil})
										next nX

										// Funcao que veririca se este item ja existe
										If ExisteSC7(SC7->C7_NUM,StrZero(nItem,4),@nRecnoSC7)
											aadd(aItem , {"C7_REC_WT" , nRecnoSC7 			, Nil})
										EndIf

										aadd(aItens,aClone(aItem))

										// adiciono no array de CRC's para depois redistribuir nos itens do pedido gerado
										aadd(aCRC,{ZE4->ZE4_FILIAL + ZE4->ZE4_NUMERO + ZE4->ZE4_PEDIDO + ZE4->ZE4_ITEMPE + ZE4->ZE4_SEQ + ZE4->ZE4_ITEM , StrZero(nItem,4) })

										// adiciono no array de amostras para depois replicar para os novos itens do pedido gerado
										aadd(aItemAmostra,StrZero(nItem,4))

										// incremento contator da quantidade do CRC
										nQtdZE4 += ZE4->ZE4_QTDE

										// incremento o contator de itens do pedido
										nItem++

									EndIf

								EndIf

							EndIf

							ZE4->(DbSkip())

						EndDo

					EndIf

					aadd(aAmostra,{ SC7->C7_NUM + SC7->C7_ITEM , aClone(aItemAmostra) })

					If nQtdSC7 == nQtdZE4
						lAprova := .T.
					Else
						lAprova := .F.
						Exit
					EndIf

					SC7->(DbSkip())

				EndDo

				If lAprova

					If MsgYesNo("Deseja aprovar o cadastro do CRC?","Atenção")

						MsAguarde( {|| lGerouPed := AtuPedido(ZE3->ZE3_PEDIDO,aCab,aItens) }, "Aguarde", "Atualizando o pedido de compras...", .F. )

						If lGerouPed

							// atualizo as amostras
							MsAguarde( {|| AtuAmostra(aAmostra) }, "Aguarde", "Atualizando as amostras...", .F. )

							// atualizo o CRC
							MsAguarde( {|| AtuCRC(aCRC) }, "Aguarde", "Atualizando o CRC...", .F. )

						EndIf

					EndIf

				EndIf

			Else
				Help(,,'Help',,"Pedido de compra inválido!",1,0)
			EndIf
		Else
			Help(,,'Help',,"CRC já aprovado ou cancelado!",1,0)
		EndIf

	Else
		Help(,,'Help',,"Selecione o CRC!",1,0)
	EndIf

	RestArea(aArea)
	RestArea(aAreaSC7)
	RestArea(aAreaZE4)
	RestArea(aAreaZE0)
	RestArea(aAreaMHZ)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} AtuCRC
Função que atualiza o status do CRC
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function AtuCRC(aCRC)

	Local nX 		:= 1
	Local aArea		:= GetArea()
	Local aAreaZE4	:= ZE4->(GetArea())

// atualizo o status da ZE3
	If Reclock("ZE3",.F.)

		ZE3->ZE3_USULIB := RetCodUsr()
		ZE3->ZE3_STATUS := '2' //CRC FINALIZADO
		ZE3->(Msunlock())

	EndIf

// faço a redistribuição dos itens do CRC para os novos itens do pedido de compras
	For nX := 1 To Len(aCRC)

		ZE4->(DbSetOrder(3)) // ZE4_FILIAL + ZE4_NUMERO + ZE4_PEDIDO + ZE4_ITEMPE + ZE4_SEQ + ZE4_ITEM
		If ZE4->(DbSeek(aCRC[nX,1]))

			If RecLock("ZE4",.F.)

				ZE4->ZE4_ITEMPE := aCRC[nX,2]
				ZE4->(MsUnLock())

			EndIf

		EndIf

	Next nX

	RestArea(aAreaZE4)
	RestArea(aArea)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} AtuAmostra
Função que atualiza as amostras
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function AtuAmostra(aAmostra)

	Local aArea	   		:= GetArea()
	Local aAreaZE5 		:= ZE5->(GetArea())
	Local nX, nY, nZ
	Local aCampos  		:= {}
	Local cCampoZE5		:= ""
	Local aNewAmostra	:= {}

	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

// aAmostra:
// Posição 1: SC7->C7_NUM + SC7->C7_ITEM
// Posição 2: Array de itens 

// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)
	lOpen := Select(cAliasSX3) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 1 ) ) //X3_ARQUIVO+X3_ORDEM
	(cAliasSX3)->( DbGoTop() )

	For nX := 1 To Len(aAmostra)

		ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
		If ZE5->(DbSeek(xFilial("ZE5") + aAmostra[nX,1]))

			While ZE5->(!Eof()) .AND. ZE5->ZE5_FILIAL == xFilial("ZE5") .AND. (ZE5->ZE5_PEDIDO + ZE5->ZE5_ITEMPE) == aAmostra[nX,1]

				aCampos := {}

				// Gravo o histório do cabeçalho do atendimento
				If (cAliasSX3)->(DbSeek("ZE5"))

					While (cAliasSX3)->(!EoF()) .AND. (cAliasSX3)->&("X3_ARQUIVO") == "ZE5"

						If (cAliasSX3)->&("X3_CONTEXT") <> "V"
							cCampoZE5 := (cAliasSX3)->&("X3_CAMPO")
							aadd(aCampos , {cCampoZE5 , ZE5->&cCampoZE5})
						EndIf

						(cAliasSX3)->(DbSkip())

					EndDo

				EndIf

				aadd(aNewAmostra , { aClone(aCampos) , aClone(aAmostra[nX,2]) })

				If RecLock("ZE5",.F.)
					ZE5->(DbDelete())
					ZE5->(MsUnLock())
				EndIf

				ZE5->(DbSkip())

			EndDo

		EndIf

	Next nX

// incluo novamente as amostras
	For nX := 1 To Len(aNewAmostra)

		For nY := 1 To Len(aNewAmostra[nX,2])

			If RecLock("ZE5",.T.)

				For nZ := 1 To Len(aNewAmostra[nX,1])

					ZE5->&(aNewAmostra[nX,1,nZ,1]) := aNewAmostra[nX,1,nZ,2]

				Next nZ

				ZE5->ZE5_ITEMPE := aNewAmostra[nX,2,nY]

				ZE5->(MsUnLock())

			EndIf

		Next nY

	Next nX

	RestArea(aAreaZE5)
	RestArea(aArea)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} ExisteSC7
Função verifica se existe o item no pedido de compra
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function ExisteSC7(cPedido,cItem,nRecnoSC7)

	Local aArea		:= GetArea()
	Local aAreaSC7	:= SC7->(GetArea())
	Local lRet		:= .F.

// verifico se existe este item do pedido       
	SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
	If SC7->(DbSeek(xFilial("SC7") + cPedido + cItem))
		nRecnoSC7 	:= SC7->(RECNO())
		lRet		:= .T.
	EndIf

	RestArea(aAreaSC7)
	RestArea(aArea)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} AtuPedido
Função que chama o execauto do pedido de compras
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function AtuPedido(cPedido,aCabecalho,aItens)

	Local aArea			:= GetArea()
	Local aAreaSC7		:= SC7->(GetArea())
	Local lRet			:= .F.
	Private lMsHelpAuto	:= .T.
	Private lMsErroAuto := .F.

	SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
	SC7->(DbGoTop())
	If SC7->(DbSeek(xFilial("SC7") + cPedido))

		// Consiero o campo C7_TIPO - G.SAMPAIO - 13/09/2016
		MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)},SC7->C7_TIPO,aCabecalho,aItens,4)

		//MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)},1,aCabecalho,aItens,4)

		If lMsErroAuto
			MostraErro()
		Else

			// gravo o status de liberação no pedido
			SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
			SC7->(DbGoTop())
			If SC7->(DbSeek(xFilial("SC7") + cPedido))

				While SC7->(!Eof()) .AND. SC7->C7_FILIAL == xFilial("SC7") .AND. SC7->C7_NUM == cPedido

					If RecLock("SC7",.F.)

						SC7->C7_CONAPRO := "L"

						//Ajuste em função de mudança de posicionamento de itens do PC
						If !Empty(SC7->C7_XCRC) .And. C7_VALSOL == 0
							SC7->C7_BASESOL := 0
						EndIf

						SC7->(MsUnLock())

					EndIf

					SC7->(DbSkip())

				EndDo

			EndIf

			lRet := .T.

		EndIf

	EndIf

	RestArea(aArea)
	RestArea(aAreaSC7)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} VerifAmo
Função que verifica as amostras do pedido de compras
@author  Wellington Gonçalves
@since   04/01/2016
@version P12
@param 
	cPedido - Numero do pedido de compras
	cItem - Item do pedido de compras
@return cStatus:
	'1' = Amostra não cadastrada
	'2' = Amostra não aprovada
	'3' = Amostra aprovada
/*/
//-------------------------------------------------------------------
User Function VerifAmo(cPedido,cItem)

	Local aAreaZE5	:= ZE5->(GetArea())
//Local aAreaZE3	:= ZE3->(GetArea())
	Local aArea		:= GetArea()
	Local cStatus	:= ""

// posiciono no primeiro registro da tabela
	ZE5->(DbGoTop())

// verifico se existe amostra cadastrada para este item
	ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE
	If ZE5->(DbSeek(xFilial("ZE5") + cPedido + cItem))

		While ZE5->(!Eof()) .AND. ZE5->ZE5_FILIAL == xFilial("ZE5") .AND. ZE5->ZE5_PEDIDO == cPedido .AND. ZE5->ZE5_ITEMPE == cItem

			// verifico se a amostra está aprovada
			If ZE5->ZE5_APROV == 'S'
				cStatus := "3" // amostra aprovada
				Exit
			Else
				cStatus := "2" // amostra não aprovada
			EndIf

			ZE5->(DbSkip())

		EndDo

	Else
		cStatus := "1" // amostra não cadastrada
	EndIf

	RestArea(aAreaZE5)
	RestArea(aArea)

Return(cStatus)

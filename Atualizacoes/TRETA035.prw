#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'


/*/{Protheus.doc} TRETA035
Cadastro de Folhas de Cheque Troco.

@author Pablo Cavalcante / Rafael Brito
@since 16/03/2014
@version 1.0

@return ${return}, ${return_description}

@type function
/*/
User Function TRETA035()
	Local oBrowse
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'UF2' )
	oBrowse:SetDescription( 'Folhas de Cheque Troco' )

// adiciona legenda no Browser
	If lChTrOp
		oBrowse:AddLegend( "UF2_STATUS == '1' .AND. Empty(UF2_CODCX)", "GREEN" , "Em Aberto" )
		oBrowse:AddLegend( "UF2_STATUS == '1' .AND. !Empty(UF2_CODCX)", "YELLOW" , "Com Operador" )
	Else
		oBrowse:AddLegend( "UF2_STATUS == '1' .AND. Empty(UF2_PDV)", "GREEN" , "Em Aberto" )
		oBrowse:AddLegend( "UF2_STATUS == '1' .AND. !Empty(UF2_PDV)", "YELLOW" , "Em um PDV" )
	EndIf
	oBrowse:AddLegend( "UF2_STATUS == '2' .AND. !Empty(UF2_DOC) .AND. !Empty(UF2_SERIE)", "RED", "Utilizado" )
	oBrowse:AddLegend( "UF2_STATUS == '3'", "BLACK", "Inutilizado" )

	oBrowse:Activate()

Return nil

//-------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisar'   						Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  						Action 'VIEWDEF.TRETA035' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Consultar'  						Action 'U_consultaChequeTroco(.T., {UF2->UF2_BANCO, UF2->UF2_AGENCI, UF2->UF2_CONTA, UF2->UF2_NUM})' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina TITLE 'Impressão' 						ACTION 'U_UFINR480()'    	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Legenda'     						Action 'U_TRETA35A()' 		OPERATION 10 ACCESS 0
	ADD OPTION aRotina Title 'Exclusão Financeira do Cheque' 	Action 'U_TRETE29G()' 		OPERATION 10 ACCESS 0
	ADD OPTION aRotina Title 'Inutilizar Folha de Cheque'    	Action 'U_TRETE29H()' 		OPERATION 10 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
Static Function ModelDef()

	Local oStruUF2 := FWFormStruct( 1, 'UF2', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oModel

// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM035', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'UF2MASTER', /*cOwner*/, oStruUF2 )

// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Folhas de Cheque Troco' )

// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ 'UF2_FILIAL' , 'UF2_BANCO', 'UF2_AGENCI', 'UF2_CONTA', 'UF2_SEQUEN' })

// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'UF2MASTER' ):SetDescription( 'Cheques Troco' )

Return oModel

//-------------------------------------------------------------------
Static Function ViewDef()

	Local oStruUF2 := FWFormStruct( 2, 'UF2' )
	Local oModel   := FWLoadModel( 'TRETA035' )
	Local oView

// Cria o objeto de View
	oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_UF2', oStruUF2, 'UF2MASTER' )

// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )

// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_UF2', 'SUPERIOR' )

// Liga a identificacao do componente
	oView:EnableTitleView('VIEW_UF2','Cheque Troco')

// Define fechamento da tela
	oView:SetCloseOnOk( {||.T.} )

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA35A
@author pablocavalcante
@since 15/09/2014
@version 1.0

@description

Mostra a Legenda da Rotina
/*/
//-------------------------------------------------------------------
User Function TRETA35A()
Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	BrwLegenda("Folha de Cheque Troco",    "Legenda",;
		{ {"BR_VERDE",    "Em Aberto"},;
		{"BR_AMARELO",  Iif(lChTrOp,"Com Operador","Em um PDV")},;
		{"BR_VERMELHO", "Utilizada"},;
		{"BR_PRETO", 	  "Inutilizada"} })

Return

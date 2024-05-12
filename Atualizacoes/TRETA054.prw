#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} TRETA054
Cadastro de Segmentos de Limite de Credito

@author Dainlo Brito
@since 01/06=8/2023
@version 1.0
@return Nil
@type function
/*/
User Function TRETA054()

	Local oBrowse

	DbSelectArea('UC3')
	DbSelectArea('UC5')

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'UC3' )
	oBrowse:SetDescription( 'Segmentos Limite Credito' )
	oBrowse:Activate()

Return

//-------------------------------------------------------------------
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.TRETA054' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'         ACTION 'VIEWDEF.TRETA054' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'         ACTION 'VIEWDEF.TRETA054' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'         ACTION 'VIEWDEF.TRETA054' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'        ACTION 'VIEWDEF.TRETA054' OPERATION 8 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruUC3  := FWFormStruct( 1, 'UC3', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruUC5 := FWFormStruct( 1, 'UC5', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	Local bLinePost := {||TR054LinOk()}

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM054', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formul·rio de ediÁ?o por campo
	oModel:AddFields( 'UC3MASTER', /*cOwner*/, oStruUC3, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "UC3_FILIAL" , "UC3_COD" })

	// Adiciona ao modelo uma componente de grid Credito
	oModel:AddGrid( 'UC5DETAIL', 'UC3MASTER', oStruUC5 , /*bLinePre*/, bLinePost, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'UC5DETAIL', { {'UC5_FILIAL', 'xFilial( "UC5" )'}, {'UC5_COD', 'UC3_COD'} }, UC5->( IndexKey( 1 ) ) )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'UC5DETAIL' ):SetUniqueLine( { 'UC5_FILERP' } ) 

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Segmentos Limite Credito' )

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'UC5DETAIL' ):SetDescription( 'Filiais do Segmento' )

	// tira obrigatoriedade de incluir linha
	oModel:GetModel( 'UC5DETAIL' ):SetOptional(.T.)

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA054' )
	Local oView

	// Cria a estrutura a ser usada na View
	Local oStruUC3 := FWFormStruct( 2, 'UC3' )
	Local oStruUC5 := FWFormStruct( 2, 'UC5' )

	// Remove campos da estrutura
	oStruUC5:RemoveField( 'UC5_COD' )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_UC3', oStruUC3, 'UC3MASTER' )

	//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_UC5', oStruUC5, 'UC5DETAIL' )

	// Define campos que terao Auto Incremento
	oView:AddIncrementField( 'VIEW_UC5', 'UC5_ITEM' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR'	, 20 )
	oView:CreateHorizontalBox( 'INFERIOR'  	, 80 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_UC3' , 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_UC5' , 'INFERIOR' )

	// titulo dos componentes
	//oView:EnableTitleView('VIEW_UC3' ,/*'cabecalho'*/)
	oView:EnableTitleView('VIEW_UC5' , /*'item'*/)

Return oView

//validação de linha
Static Function TR054LinOk()

	Local aArea			:= GetArea()
	Local aAreaUC5		:= UC5->(GetArea())
	Local oMdl			:= FWModelActive()
	Local oMdlGrid		:= oMdl:GetModel('UC5DETAIL')
	Local cFilERP		:= oMdlGrid:GetValue('UC5_FILERP') 
	Local lRet			:= .T.

	If !oMdlGrid:IsDeleted()
		UC5->(DbSetOrder(2)) //UC5_FILIAL+UC5_FILERP
		
		If UC5->(DbSeek(xFilial("UC5")+cFilERP )) .AND. UC5->UC5_COD <> FwFldGet("UC3_COD")
			Help(,,"Atenção",,"Filial já cadastrada no segmento "+UC5->UC5_COD+"-"+Alltrim(Posicione("UC3",1,xFilial("UC3")+UC5->UC5_COD,"UC3_DESC"))+".",1,0,,,,,,{""})
			lRet := .F.
		EndIf
	EndIf

	RestArea(aAreaUC5)
	RestArea(aArea)

Return(lRet)

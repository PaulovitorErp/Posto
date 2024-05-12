#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETA051
Cadastro de bombas, bicos e lacres utilizando MVC

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
User Function TRETA051()

	Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'MHY' )
	oBrowse:SetDescription( 'Cadastro de Bombas, Bicos e Lacres' )

	// adiciona legenda no Browser
	oBrowse:AddLegend( "MHY_STATUS == '1'", "GREEN", "Ativado")
	oBrowse:AddLegend( "MHY_STATUS == '2'", "RED"  , "Desativado")

	oBrowse:Activate()

Return NIL

/*/{Protheus.doc} MenuDef
Definição do Menu

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisar'   		Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  		Action 'VIEWDEF.TRETA051' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'     		Action 'VIEWDEF.TRETA051' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     		Action 'VIEWDEF.TRETA051' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     		Action 'VIEWDEF.TRETA051' 	OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    		Action 'VIEWDEF.TRETA051' 	OPERATION 08 ACCESS 0
	ADD OPTION aRotina Title 'Copiar'      		Action 'VIEWDEF.TRETA051' 	OPERATION 09 ACCESS 0
	ADD OPTION aRotina Title 'Alterar Preço do Bico'    Action 'U_TRETE002()' 		OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Leitura de Encerrante'	Action 'U_TRETE006()'  		OPERATION 03 ACCESS 0

Return aRotina

/*/{Protheus.doc} ModelDef
Definição do Modelo

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
Static Function ModelDef()

	Local oStruMHY := FWFormStruct( 1, 'MHY', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oStruMIC := FWFormStruct( 1, 'MIC', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oStruMIB := FWFormStruct( 1, 'MIB', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oModel
	Local bRelac

	//legenda no grid de bicos
	bRelac := {|A,B,C| FwInitCPO(A,B,C), xRET:=( iif( MIC->MIC_STATUS<>"2" .and. (Empty(DtoS(MIC->MIC_XDTDES)) .or. DtoS(MIC->MIC_XDTDES)>=DtoS(Date())), "BR_VERDE", "BR_VERMELHO" ) ), FwCloseCPO(A,B,C,.T.), FwSetVarMem(A,B,xRET), xRET }
	oStruMIC:AddField('','','STATUS','C',11,0,,,{},.F.,bRelac,,,.T.)

	oStruMIC:SetProperty("MIC_STATUS" ,MODEL_FIELD_VALID  ,{|| U_TRET51VA() } )
	oStruMIC:SetProperty("MIC_XDTDES" ,MODEL_FIELD_VALID  ,{|| U_TRET51VA() } )

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM051', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	/////////////////////////  CABEÇALHO - BOMBAS  ////////////////////////////

	// Crio a Enchoice com os campos do cadastro de Tanques
	oModel:AddFields( 'MHYMASTER', /*cOwner*/, oStruMHY )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "MHY_FILIAL" , "MHY_CODBOM" })

	// Preencho a descrição da entidade
	oModel:GetModel('MHYMASTER'):SetDescription('Bomba:')


	///////////////////////////  ITENS - BICOS  //////////////////////////////

	// Crio o grid de bicos
	oModel:AddGrid('MICDETAIL', 'MHYMASTER', oStruMIC, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/)

	// Faço o relaciomaneto entre o bomba e bicos
	oModel:SetRelation('MICDETAIL', { { 'MIC_FILIAL', 'xFilial( "MIC" )' } , { 'MIC_CODBOM', 'MHY_CODBOM' } } , MIC->(IndexKey(2)))

	// Seto a propriedade de não obrigatoriedade do preenchimento do grid
	oModel:GetModel('MICDETAIL'):SetOptional(.T.)

	// Preencho a descrição da entidade
	oModel:GetModel('MICDETAIL'):SetDescription('Bicos:')

	// Não permitir duplicar o código do bico
	oModel:GetModel('MICDETAIL'):SetUniqueLine( {'MIC_CODBIC','MIC_STATUS','MIC_XDTDES'} )

	///////////////////////////  ITENS - LACRES  //////////////////////////////

	// Crio o grid de Lacres
	oModel:AddGrid('MIBDETAIL', 'MHYMASTER', oStruMIB, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/)

	// Faço o relaciomaneto entre o bicos e o Lacres
	oModel:SetRelation('MIBDETAIL', { { 'MIB_FILIAL', 'xFilial( "MIB" )' } , { 'MIB_CODBOM', 'MHY_CODBOM' }, { 'MIB_CODMAN', 'Space(6)' } } , MIB->(IndexKey(3)))

	// Seto a propriedade de não obrigatoriedade do preenchimento do grid
	oModel:GetModel('MIBDETAIL'):SetOptional(.T.)

	// Preencho a descrição da entidade
	oModel:GetModel('MIBDETAIL'):SetDescription('Lacres:')

	// Não permitir duplicar o código do lacre
	oModel:GetModel('MIBDETAIL'):SetUniqueLine( {'MIB_NROLAC'} )


Return(oModel)

/*/{Protheus.doc} ViewDef
Cria a camada de visão

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
Static Function ViewDef()

	Local oStruMHY 	:= FWFormStruct(2,'MHY')
	Local oStruMIC 	:= FWFormStruct(2,'MIC')
	Local oStruMIB 	:= FWFormStruct(2,'MIB')
	Local oModel   	:= FWLoadModel('TRETA051')
	Local oView

	// Remove campos a estrutura
	oStruMIC:RemoveField('MIC_CODBOM')
	oStruMIB:RemoveField('MIB_CODMAN')
	oStruMIB:RemoveField('MIB_CODBOM')
	oStruMIB:RemoveField('MIB_CODCON')
	oStruMIB:RemoveField('MIB_CODBIC')

	oStruMIC:AddField('STATUS',"01",'','',NIL,'GET','@BMP',,'',.F.,'','',{},1,'BR_VERDE',.T.)

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel(oModel)

	oView:AddField('VIEW_MHY'	, oStruMHY, 'MHYMASTER') // cria o cabeçalho - Bombas
	oView:AddGrid('VIEW_MIC'	, oStruMIC, 'MICDETAIL') // Cria o grid - Bicos
	oView:AddGrid('VIEW_MIB'	, oStruMIB, 'MIBDETAIL') // Cria o grid - Lacres

	// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox("PAINEL_CAB", 30)
	oView:CreateHorizontalBox("PAINEL_DET", 70)

	// Cria Folder na view
	oView:CreateFolder("PASTAS","PAINEL_DET")

	// Cria pastas nas folders
	oView:AddSheet("PASTAS","ABA01"," Bicos ")
	oView:AddSheet("PASTAS","ABA02"," Lacres ")

	oView:CreateHorizontalBox("PAINEL_BICOS",100,,,"PASTAS","ABA01")
	oView:CreateHorizontalBox("PAINEL_LACRES",100,,,"PASTAS","ABA02")

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView('VIEW_MHY','PAINEL_CAB')
	oView:SetOwnerView("VIEW_MIC","PAINEL_BICOS")
	oView:SetOwnerView("VIEW_MIB","PAINEL_LACRES")

	// Liga a identificacao do componente
	oView:EnableTitleView("VIEW_MHY","Bombas")
	oView:EnableTitleView("VIEW_MIC","Bicos")
	oView:EnableTitleView("VIEW_MIB","Lacres")

	// Define fechamento da tela ao confirmar a operação
	oView:SetCloseOnOk({||.T.})

Return(oView)


/*/{Protheus.doc} TRET51VA
Funcao para validar dados informado
- chamado na validacao de campo.

@author pablo
@since 09/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function TRET51VA()

	Local oModel     	:= FWModelActive()
	Local oModelMIC  	:= oModel:GetModel( 'MICDETAIL' )
	Local lRet			:= .T.

	if (ReadVar() == "M->MIC_STATUS") .or. (ReadVar() == "M->MIC_XDTDES")

		cStatus := iif( oModelMIC:GetValue("MIC_STATUS")<>"2" .and. (Empty(DtoS(oModelMIC:GetValue("MIC_XDTDES"))) .or. DtoS(oModelMIC:GetValue("MIC_XDTDES"))>=DtoS(Date())), "BR_VERDE", "BR_VERMELHO" )
		oModelMIC:LoadValue('STATUS', cStatus)

		if ReadVar() == "M->MIC_STATUS" 
			//preencho a data desativação automaticamente
			if cStatus == "BR_VERMELHO"
				oModelMIC:LoadValue("MIC_XDTDES", Date())
			else
				oModelMIC:LoadValue("MIC_XDTDES", STOD(""))
			endif
		endif

	EndIf

Return lRet

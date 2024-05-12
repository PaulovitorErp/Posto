#include "protheus.ch"
#include "fwmvcdef.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETA015
Cadastro de Medição de Tanque

@author pablo
@since 11/04/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA015()   

Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('TQK')
	oBrowse:SetDescription('Medição de Tanque')
	oBrowse:Activate()

Return NIL

/************************/
Static Function MenuDef()
/************************/

Local aRotina := {}

	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.TRETA015" OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.TRETA015" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.TRETA015" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.TRETA015" OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Imprimir"   ACTION "VIEWDEF.TRETA015" OPERATION 8 ACCESS 0
	//ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.TRETA015" OPERATION 9 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruTQK := FWFormStruct(1,"TQK",/*bAvalCampo*/,/*lViewUsado*/)
Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New("TRETM015",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/)
	
	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields("TQKMASTER",/*cOwner*/,oStruTQK,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/)
	
	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({"TQK_FILIAL","TQK_TANQUE","TQK_DTMEDI","TQK_HRMEDI"})
	
	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription("Medições")
	
	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel("TQKMASTER"):SetDescription("Medição de Tanque")

Return oModel

/************************/
Static Function ViewDef()
/************************/

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel := FWLoadModel("TRETA015")

// Cria a estrutura a ser usada na View
Local oStruTQK := FWFormStruct(2,"TQK")

Local oView

	// Cria o objeto de View
	oView := FWFormView():New()
	
	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )
	
	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_TQK', oStruTQK, 'TQKMASTER' )
	
	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )
	
	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_TQK', 'SUPERIOR' )
	
	// Liga a identificacao do componente
	oView:EnableTitleView('VIEW_TQK')   
	
	// Define fechamento da tela
	oView:SetCloseOnOk( {||.T.} )

Return oView

/*/{Protheus.doc} TRET015A
Atualiza campo de estoque e capacidade.

@author pablo
@since 26/10/2018
@version 1.0
@return ${return}, ${return_description}
@param cTq, characters, descricao
@param nMedida, numeric, descricao
@type function
/*/
User Function TRET015A(cTq,nMedida)

	dbSelectArea("ZE0")
	ZE0->(dbSetOrder(1)) //ZE0_FILIAL+ZE0_TANQUE
	
	If ZE0->(dbSeek(xFilial("ZE0")+cTq))
	
		dbSelectArea("ZE6")
		ZE6->(dbSetOrder(1)) //ZE6_FILIAL+ZE6_TABELA
			
	    If ZE6->(dbSeek(xFilial("ZE6")+ZE0->ZE0_TABVOL))
	    	
	    	dbSelectArea("ZE7")
	    	ZE7->(dbSetOrder(1)) //ZE7_FILIAL+ZE7_CODIGO+ZE7_MEDIDA
	    	
	    	If ZE7->(dbSeek(xFilial("ZE7")+ZE6->ZE6_TABELA+cValToChar(nMedida)))
	    		M->TQK_QTDEST 	:= ZE7->ZE7_VOLUME
	    		M->TQK_QTDMED	:= ZE7->ZE7_VOLUME
	    		M->TQK_CAPAC	:= ZE0->ZE0_CAPAC - ZE7->ZE7_VOLUME
	    	EndIf
	    	
	    EndIf
	EndIf

Return .T.


/*/{Protheus.doc} TRET015B
Valida medição retroativa

@author Totvs TBC
@since 28/10/2014
@version 1.0

@type function
/*/
User Function TRET015B() 

Local lRet	:= .T.
Local cQry 	:= ""

If !Empty(M->TQK_TQFISC) .And. !Empty(M->TQK_DTMEDI) .And. !Empty(M->TQK_HRMEDI)

	If Select("QRYMED") > 0
		QRYMED->(dbCloseArea())
	EndIf                                              
	
	cQry := "SELECT TQK_HRMEDI"
	cQry += " FROM " + RetSqlName("TQK") + ""
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND TQK_FILIAL  = '" + xFilial("TQK") + "'"
	cQry += " AND TQK_TQFISC = '" + M->TQK_TQFISC + "'"
	cQry += " AND TQK_DTMEDI = '" + DToS(M->TQK_DTMEDI) + "'"
	cQry += " AND TQK_HRMEDI >= '" + M->TQK_HRMEDI + "' "
	
	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYMED"
	
	If QRYMED->(!EOF())
		cMsg := "Já existe medição para o tanque fisico <"+M->TQK_TQFISC+">, data <"+DToC(M->TQK_DTMEDI)+"> e hora <"+Transform(QRYMED->TQK_HRMEDI,"@R 99:99")+">. Não é permitido cadastrar medição retroativa!"
		Help(,,'Help',,cMsg,1,0)
		lRet :=  .F.
	EndIf

	If Select("QRYMED") > 0
		QRYMED->(dbCloseArea())
	EndIf

EndIf
	
Return lRet

#INCLUDE "Protheus.ch"
#INCLUDE "Topconn.ch"
#INCLUDE "FWMVCDEF.CH"
#include "tbiconn.ch"

/*/{Protheus.doc} TRETA048
Cadastro de amostra de combust�vel - CRC
@author Totvs TBC
@since 27/05/2014
@version 1.0
@return Nulo

@type function
/*/
User Function TRETA048()

Private oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias('ZE5')
oBrowse:SetDescription('CADASTRO DE AMOSTRAS DE COMBUSTIVEL')  

// adiciona legenda no Browser
oBrowse:AddLegend( "ZE5_APROV == 'S' .AND. EMPTY(ZE5_CRC) .AND. EMPTY(ZE5_DOC)", "GREEN", "Aprovado")
oBrowse:AddLegend( "ZE5_APROV <> 'S'", "BLACK"  , "Nao aprovado") 
oBrowse:AddLegend( "ZE5_APROV == 'S' .AND. !EMPTY(ZE5_CRC) .AND. EMPTY(ZE5_DOC)", "YELLOW"  , "Com CRC")
oBrowse:AddLegend( "ZE5_APROV == 'S' .AND. !EMPTY(ZE5_CRC) .AND. !EMPTY(ZE5_DOC)", "RED"  , "Finalizado")
                             
oBrowse:Activate()

Return NIL
//---------------------------------------------------------------------------------------------------------
Static function menudef()

Private aRotina:={}

// Wellington Gon�alves dia 10/12/2015   
if Type("obrowse") <> "U"
	obrowse:SetMenuDef("TRETA048") 
endif

ADD OPTION aRotina Title 'Visualizar' Action 'VIEWDEF.TRETA048' 	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Incluir'    Action 'VIEWDEF.TRETA048' 	OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Alterar'    Action 'VIEWDEF.TRETA048' 	OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Excluir'    Action 'VIEWDEF.TRETA048' 	OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Imprimir'   Action 'VIEWDEF.TRETA048' 	OPERATION 8 ACCESS 0   
ADD OPTION aRotina Title 'Legenda'    Action 'U_TRET048L()' 	OPERATION 10 ACCESS 0    

Return aRotina

//---------------------------------------------------------------------------------------------------------
Static function ModelDef()

Local oStruZE5 := FWFormStruct( 1, 'ZE5', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

oModel := MPFormModel():New('TRETM048', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
oModel:AddFields('ZE5MASTER', /*cOwner*/, oStruZE5 )
oModel:SetDescription( 'Dados Amostra')
oModel:GetModel('ZE5MASTER' ):SetDescription( 'Dados da Amostra de Comb.')
oModel:SetPrimaryKey({"ZE5_FILIAL","ZE5_PEDIDO","ZE5_ITEMPE"})

Return oModel

//---------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oStruZE5 	:= FWFormStruct( 2, 'ZE5' )
Local oModel   	:= FWLoadModel( 'TRETA048' )    
Local bBloco 	:= {|oView| UIniPedZE5(oView)}
Local oView

oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( 'VIEW_ZE5', oStruZE5, 'ZE5MASTER' )
oView:CreateHorizontalBox( 'EMCIMA' , 100 )
oView:EnableTitleView( 'VIEW_ZE5' ,'Dados da Amostra')

oView:SetCloseOnok({||.F.})   

oView:SetAfterViewActivate(bBloco) 

Return oView

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � TRET048L � Autor� Wellington Gon�alves� Data � 10/12/2015  ���
�������������������������������������������������������������������������͹��
���Desc.     � Fun��o que mostra a legenda da amostra					  ���
���          � 										                      ���
�������������������������������������������������������������������������͹��
���Uso       � Maraj�                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function TRET048L()

BrwLegenda("Status da amostra","Legenda",{ {"BR_VERDE","Aprovado"},{"BR_PRETO","Nao aprovado"},{"BR_AMARELO","Com CRC"},{"BR_VERMELHO","Finalizado"} })

Return() 

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � UIniPedZE5 �Autor� Wellington Gon�alves �Data � 05/01/2016 ���
�������������������������������������������������������������������������͹��
���Desc.     � Fun��o chamada na abertura da tela.						  ���
���          � Caso a inclus�o seja chamada da rotina de pedido de        ��� 
���          � compras, vir� com o campo do pedido preenchido.		      ���
�������������������������������������������������������������������������͹��
���Uso       � Maraj�                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

Static Function UIniPedZE5(oView)  

Local nOperation := oView:GetOperation()

// apenas se for inclus�o
If nOperation == 3 

	If AllTrim(FunName()) == "MATA120" .OR. AllTrim(FunName()) == "MATA121"
        
		// preencho com o n�mero do pedido de compras posicionado
		FwFldPut("ZE5_PEDIDO",SC7->C7_NUM,,,,.T.) 
		FwFldPut("ZE5_ITEMPE",SC7->C7_ITEM,,,,.T.)
		FwFldPut("ZE5_PRODUT",SC7->C7_PRODUTO,,,,.T.)
		FwFldPut("ZE5_DESCRI",AllTrim(Posicione("SB1",1,xFilial("SB1") + SC7->C7_PRODUTO , "B1_DESC")),,,,.T.)
		
		// refresh na view
		oView:Refresh()     
		
	EndIf 
	
endif

Return()

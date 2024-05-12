#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETM037
Ponto de Entrada da Rotina de Perfil Controle de Acesso / Alçada
@author thebr
@since 20/09/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETM037()  

Local aParam     := PARAMIXB 
Local oObj       := aParam[1]
Local cIdPonto   := aParam[2]
Local cIdModel   := IIf( oObj<> NIL, oObj:GetId(), aParam[3] ) //cIdModel   := aParam[3]
Local cClasse    := IIf( oObj<> NIL, oObj:ClassName(), '' ) 
Local nOperation := IIf( oObj<> NIL, oObj:GetOperation(), 0) 
Local oModelU03, oModelU04, oModelU0D, oModelUC2
Local xRet       := .T. 
Local lIsGrid    := .F. 
Local nLinha     := 0 
Local nQtdLinhas := 0 
Local cOperad 	 := "" 
Local nX
Local cUserAdm  
Local cUsuario 

If aParam <> NIL 
	
	oObj       := aParam[1]
	cIdPonto   := aParam[2]
	cIdModel   := IIf( oObj<> NIL, oObj:GetId(), aParam[3] ) //cIdModel   := aParam[3]
	cClasse    := IIf( oObj<> NIL, oObj:ClassName(), '' ) 
    nOperation := IIf( oObj<> NIL, oObj:GetOperation(), 0)
	
	lIsGrid    := ( Len( aParam ) > 3 ) .and. cClasse == 'FWFORMGRID'

	If lIsGrid
		nQtdLinhas := oObj:GetQtdLine() 
		nLinha     := oObj:nLine 
	EndIf 
	
	If cIdPonto == 'MODELVLDACTIVE'  
  	ElseIf cIdPonto == 'BUTTONBAR'  
	ElseIf cIdPonto == 'FORMLINEPRE' 
	ElseIf cIdPonto ==  'FORMPRE'
	ElseIf cIdPonto == 'FORMPOS'  
        
        //valido informar um usuario ou grupo
        oModelU03 := FWModelActive()
		if empty(oModelU03:GetValue("U03MASTER",'U03_USER') + oModelU03:GetValue("U03MASTER",'U03_GRUPO'))
			Help( ,, 'Help',, 'Informe um usuário ou grupo de usuário.', 1, 0 ) 
			xRet := .F.
		endif
		 
	ElseIf cIdPonto == 'FORMLINEPOS' 
  	ElseIf cIdPonto ==  'MODELPRE'
	ElseIf cIdPonto == 'MODELPOS' 
	ElseIf cIdPonto == 'FORMCOMMITTTSPRE'
	ElseIf cIdPonto == 'FORMCOMMITTTSPOS' 
	ElseIf cIdPonto == 'MODELCOMMITTTS' 
    ElseIf cIdPonto == 'MODELCOMMITNTTS' 
        
        cUserAdm  := SuperGetMv("MV_XUSRADM",,"") //Usuários Administradores
        cUsuario := RetCodUsr()

		//Envio os registros para os PDVs
		if oObj:GetOperation() == 3 // inclusão
			cOperad := "I"
		elseif oObj:GetOperation() == 4 //alteração  
			cOperad := "A"
		elseif oObj:GetOperation() == 5  //exclusão
			cOperad := "E"
		endif
        
        //Não replico para o PDV tabela principal, pois nao usa pra nada
        oModelU03 := oObj:GetModel( 'U03MASTER' )

        //Outras Alçadas
        oModelU0D := oObj:GetModel( 'U0DDETAIL' )
        U_UREPLICA("U0D", 1, xFilial("U0D") + oModelU03:GetValue('U03_GRUPO') + oModelU03:GetValue('U03_USER'), cOperad) 
        
        //Alçadas Desconto
        oModelU04 := oObj:GetModel( 'U04DETAIL' )
        For nX := 1 To oModelU04:Length()
			// posiciono na linha atual
			oModelU04:Goline(nX)

			if oModelU04:IsDeleted(nX)
				// envio o lacre para a tabela de saída
				U_UREPLICA("U04",1,xFilial("U04") + oModelU03:GetValue('U03_GRUPO') + oModelU03:GetValue('U03_USER') + oModelU04:GetValue('U04_ITEM') , "E")
			else
				// envio o lacre para a tabela de saída
				U_UREPLICA("U04",1,xFilial("U04") + oModelU03:GetValue('U03_GRUPO') + oModelU03:GetValue('U03_USER') + oModelU04:GetValue('U04_ITEM') , cOperad)
			endif
        Next nX
        
        //Alçadas Desconto
        if cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador
            oModelUC2 := oObj:GetModel( 'UC2DETAIL' )
            For nX := 1 To oModelUC2:Length()
                // posiciono na linha atual
                oModelUC2:Goline(nX)
                //UC2_FILIAL+UC2_GRUPO+UC2_USER+UC2_ROTINA
                if oModelUC2:IsDeleted(nX)
                    // envio o lacre para a tabela de saída
                    U_UREPLICA("UC2",1,xFilial("UC2") + oModelU03:GetValue('U03_GRUPO') + oModelU03:GetValue('U03_USER') + oModelUC2:GetValue('UC2_ROTINA') , "E")
                else
                    // envio o lacre para a tabela de saída
                    U_UREPLICA("UC2",1,xFilial("UC2") + oModelU03:GetValue('U03_GRUPO') + oModelU03:GetValue('U03_USER') + oModelUC2:GetValue('UC2_ROTINA') , cOperad)
                endif
            Next nX
        endif

 	ElseIf cIdPonto == 'MODELCANCEL' 
 	EndIf
 	 
EndIf 

Return xRet

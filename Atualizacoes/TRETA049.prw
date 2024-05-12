#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA049
Rotina de Acompanhamento de Hist�rico de Pre�os

27/07/2020 - Danilo
Altera��o para escolher acompanhar hist�rioco de:
Pre�o Negociado - fonte TRETA49A
Pre�o Base  - fonte TRETA49B
Ao chamar rotina, � perguntado qual pre�o quer acompanhar o historico

@param xParam Parameter Description
@return xRet Return Description
@author Danilo
@since 06/04/2020
/*/
User function TRETA049(_lCadCli)

    Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negocia��o pelo valor de desconto: U25_DESPBA
    Local nRet
    Default _lCadCli		:= .F. 

    if lNgDesc .AND. !_lCadCli
        nRet := Aviso("Hist�rioco de Pre�os", "Escolha qual vis�o deseja ter na rotina de acompanhamento de hist�rico de pre�os:", {"Pre�o Base", "Pre�o Negociado"}, 2)

        if nRet == 1
            U_TRETA49B(_lCadCli) //pre�o base
        else
            U_TRETA49A(_lCadCli) //pre�o negociado
        endif
    else
        U_TRETA49A(_lCadCli)
    endif

Return
